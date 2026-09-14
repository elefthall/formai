# Mobile Pose Detection

## Pipeline

```text
CameraImage
→ single-flight gate
→ platform image/rotation adapter
→ Google ML Kit Pose Detector
→ SDK landmarks
→ normalized PoseFrame
→ pose validation
→ movement analyzer
```

## SDK Strategy

MVP는 Google ML Kit Pose Detection을 우선 spike한다. `PoseDetectionService`가 SDK type을 infrastructure에 가둔다. 실제 Android/iOS에서 ≥10 FPS, required likelihood, offline/on-device 처리, resource close가 충족되지 않으면 MediaPipe native adapter를 비교한다.

## Required Joints

- left/right shoulder
- left/right hip
- left/right knee
- left/right ankle

`JointType` enum과 `Map<JointType, PosePoint>`로 매핑한다. SDK landmark enum/index를 Widget이나 analyzer에서 사용하지 않는다.

## Domain Models

```dart
enum JointType {
  leftShoulder, rightShoulder,
  leftHip, rightHip,
  leftKnee, rightKnee,
  leftAnkle, rightAnkle,
}

class PosePoint {
  const PosePoint({
    required this.x,
    required this.y,
    required this.z,
    required this.confidence,
  });
  final double x;
  final double y;
  final double z;
  final double confidence;
}

class PoseFrame {
  const PoseFrame({required this.timestamp, required this.joints});
  final DateTime timestamp;
  final Map<JointType, PosePoint> joints;
}
```

## Coordinate Contract

- domain coordinates는 upright, unmirrored image 기준 normalized x/y [0,1]이다.
- adapter가 Android sensor rotation, iOS orientation, front-camera mirror를 보정한다.
- preview mirror는 presentation transform이며 joint left/right semantic을 바꾸지 않는다.
- PosePainter는 camera preview의 aspect-fit/cover crop, device orientation, canvas size를 같은 transform으로 적용한다.
- angle 계산은 preview pixel이 아니라 normalized coordinates를 사용한다. 2D aspect distortion을 막기 위해 source width/height 보정을 적용한다.

## Camera Image Mapping

adapter input metadata:

- bytes/planes는 호출 lifetime 동안만 참조
- width/height
- format (Android YUV420/NV21 지원 여부, iOS BGRA8888 등)
- sensor orientation
- device orientation
- lens direction
- monotonic timestamp

지원 format은 선택한 plugin/SDK 공식 matrix를 구현 시 확인한다. 변환 실패 frame은 drop하고 queue에 쌓지 않는다.

## Confidence and Validity

초기 minimum landmark confidence는 `0.5`다. 선택 side hip/knee/ankle 및 양쪽 정렬용 shoulder/hip/knee/ankle이 기준을 충족해야 한다.

Invalid reason:

```dart
enum PoseInvalidReason {
  personMissing,
  partialBody,
  lowConfidence,
  requiredLandmarkMissing,
  bodyOutOfFrame,
  nonFiniteCoordinate,
}
```

count 금지 조건:

- pose 없음 또는 여러 사람으로 primary pose가 불명확
- required joint 누락
- confidence <0.5
- coordinate NaN/Infinity/비정상 범위
- shoulder-to-ankle span이 초기 화면 비율보다 작음
- required joint가 safe margin 밖

threshold/safe margin은 **추가 검증 필요**다.

## Missing Pose

- 짧은 invalid 구간에서는 transition을 진행하지 않는다.
- 연속 손실이 설정 시간(초기 500ms)을 넘으면 incomplete attempt와 EMA를 reset한다.
- pose가 안정적으로 복구되고 standing을 다시 확인하기 전 count를 재개하지 않는다.
- 누락 구간 interpolation으로 rep을 완성하지 않는다.

UI:

- 사람이 감지되지 않았어요.
- 전신이 화면에 나오도록 조금 뒤로 이동해주세요.
- 카메라가 신체를 인식하도록 자세를 조정해주세요.

## Frame Scheduling

- preview target ≥24 FPS.
- inference target 10~15 FPS.
- `_isProcessingFrame`가 true면 새 frame을 drop한다.
- inference 종료는 `finally`에서 guard를 해제한다.
- UI update는 필요한 상태 변화/제한된 주기로만 수행한다.
- CameraImage, SDK image, result object를 장기간 보관하지 않는다.

```dart
if (_isProcessingFrame) return;
_isProcessingFrame = true;
try {
  final poseFrame = await detector.process(input);
  controller.onPoseFrame(poseFrame);
} finally {
  _isProcessingFrame = false;
}
```

## Lifecycle

| Event | Behavior |
|---|---|
| foreground start | permission → camera → detector → stream |
| inactive/paused | stop stream; cancel analysis; release camera/detector |
| screen lock/call | same as paused; incomplete rep reset |
| resumed | permission 재검사; new controller/detector; alignment |
| permission revoked | error state + settings 안내 |
| camera unavailable | retryable error; 다른 lens 제안 |
| route leave | stop/close/dispose idempotently |

## Skeleton Overlay

- required joint confidence ≥0.5인 점/선만 그린다.
- line connections: shoulder, torso, hip, upper/lower arms, upper/lower legs.
- valid는 green, low confidence는 amber/text, invalid는 overlay 축소 + 안내.
- painter는 immutable lightweight pose snapshot만 받고 SDK object/CameraImage를 받지 않는다.
- `shouldRepaint`는 pose/frame ID나 transform 변화 기준으로 제한한다.

## Performance Instrumentation

기기 내 개발 metric: preview FPS, inference FPS, inference latency, dropped frame count, memory trend. raw coordinates/frame은 analytics로 전송하지 않는다. 5분/15분 workout에서 발열과 throttling을 실기기로 기록한다.
