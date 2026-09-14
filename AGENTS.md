# FormAI Agent Guide

## Project Mission

FormAI는 Android와 iOS를 Flutter 단일 코드베이스로 제공하는 on-device AI 운동 자세 코칭 모바일앱이다. 웹앱으로 구현하지 않는다. MVP는 스쿼트 자동 카운트이며 통제된 환경에서 10회를 9~11회로 인식한다.

## Mandatory Reading

구현 전 `README.md`와 `docs/` 전체를 읽는다. 충돌 시 Security/Privacy → Squat Algorithm → Architecture → PRD 순으로 우선한다.

## MVP Priority

```text
Camera → Pose Detection → PoseFrame → Knee Angle → EMA
→ Squat State Machine → Rep Count → Flutter UI → Workout Result
```

앞 단계가 검증되기 전 뒤 단계나 부가 기능을 우선하지 않는다.

## Architecture Rules

- Flutter feature-first + Clean Architecture Lite를 사용한다.
- Pose SDK는 `PoseDetectionService` adapter 뒤에 둔다.
- Widget이 camera/pose SDK나 운동 알고리즘을 직접 호출하지 않는다.
- angle, EMA, validation, state machine은 Flutter/ML SDK 비의존 pure Dart다.
- dependency flow는 UI → WorkoutController → service/analyzer다.
- frame은 처리 직후 폐기하며 state, collection, log에 보관하지 않는다.

## Coding and Lifecycle Rules

- Dart strong typing, immutable model, enum/sealed state를 사용한다.
- `dynamic`, null assertion, 분석 경고 무시를 남용하지 않는다.
- 이름에 단위를 표시한다: `timestampMs`, `angleDeg`, `durationSeconds`.
- inference는 single-flight이며 밀린 frame은 drop한다.
- inactive/paused/detached에서 image stream을 중단하고 camera/detector를 release한다.
- resume 시 permission과 camera availability를 재검증하고 alignment부터 시작한다.
- `CameraController.dispose()`와 detector `close()`를 반드시 보장한다.

## Security Rules

- video/photo/raw frame을 network, DB, Storage, analytics, log, LLM에 보내지 않는다.
- service role, LLM secret, admin/private key를 앱에 포함하지 않는다.
- 앱에는 Supabase publishable key만 허용하며 RLS를 전제로 한다.
- AI Coach는 Edge Function을 통해서만 호출한다.
- 실제 `.env`와 secret 파일은 commit하지 않는다.

## Testing Rules

- pure Dart 핵심 로직은 unit test가 필수다.
- camera/pose를 mock하고 PoseFrame fixture로 integration test한다.
- lifecycle disposal과 single-flight guard를 테스트한다.
- Pose acceptance는 실제 Android/iPhone에서 수행한다.
- 완료 전 format, analyze, test, Android/iOS build를 실행한다.


## AI Usage Rules

- 실시간 rep 판정에 LLM을 사용하지 않는다.
- AI는 종료 후 structured metrics만 받는다.
- AI가 rep을 수정하거나 측정값을 생성하게 하지 않는다.
- 의료·부상 진단과 안전 보장을 금지한다.

## Forbidden Changes

- Flutter 대신 웹/React/Next.js 제품 구현
- raw frame 업로드·저장·녹화
- Widget 내부 pose/angle/state-machine 로직
- test 없는 threshold 변경
- secret의 mobile embedding
- MVP 전 결제, 소셜, 추가 운동, 음성 코칭
- 핵심과 무관한 대규모 refactoring

## Definition of Done

`docs/17_DEFINITION_OF_DONE.md`를 따른다. emulator/자동 테스트만으로 camera AI 완료를 주장하지 않는다.
