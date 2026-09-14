# Mobile MVP Definition of Done

## Project

- [ ] Flutter stable project가 Android/iOS를 빌드한다.
- [ ] feature-first 구조, Riverpod, go_router가 최소 범위로 구성된다.
- [ ] package/min OS/model/analyzer version이 기록된다.

## Camera and Lifecycle

- [ ] rationale 뒤 camera permission을 요청한다.
- [ ] granted/denied/permanently denied/unavailable을 처리한다.
- [ ] preview가 target device에서 ≥24 FPS다.
- [ ] foreground/background/lock/call/revoke/resume을 처리한다.
- [ ] route leave/background에서 CameraController가 dispose되고 indicator가 꺼진다.

## Pose

- [ ] Pose Detection은 on-device에서 동작한다.
- [ ] required 8 joints와 confidence를 PoseFrame으로 매핑한다.
- [ ] rotation/mirror/aspect를 보정한 skeleton이 정렬된다.
- [ ] confidence <0.5, missing/partial/out-of-frame에서 count를 중지한다.
- [ ] inference ≥10 FPS, single-flight, frame backlog 0이다.
- [ ] detector가 모든 종료 경로에서 close된다.

## Squat

- [ ] angle 0~180 pure Dart와 EMA 0.35.
- [ ] standing 155°, bottom 105°, ROM 45°, cooldown 400ms.
- [ ] full cycle만 count한다.
- [ ] shallow/bounce/jitter/pose loss/pause가 오카운트하지 않는다.
- [ ] 10회→9~11 실기기 validation을 통과한다.

## UI and Result

- [ ] alignment, active, pause, result가 동작한다.
- [ ] 큰 counter, color+text, semantics, text scaling, 48dp target.
- [ ] reps/duration/aggregate metrics를 표시한다.
- [ ] network failure에도 local result를 유지한다.

## Privacy and Security

- [ ] video/photo/frame/raw landmark network/storage 요청 0.
- [ ] 앱 bundle의 service role/LLM/admin secret 0.
- [ ] Android/iOS 최소 permission만 선언한다.
- [ ] log/crash report가 민감 데이터를 포함하지 않는다.
- [ ] cloud 사용 시 RLS cross-user test가 통과한다.

## Tests and Build

- [ ] angle/EMA/validity/state/counter unit tests.
- [ ] camera lifecycle/single-flight integration tests.
- [ ] widget accessibility tests.
- [ ] fake PoseFrame E2E.
- [ ] 실제 Android와 iPhone smoke/accuracy/performance test.
- [ ] `dart format`, `flutter analyze`, `flutter test` 통과.
- [ ] Android build와 iOS no-codesign build 통과.

## Documentation

- [ ] README setup/commands가 실제 project와 일치한다.
- [ ] 알려진 기기/촬영 제한과 추가 검증 항목을 기록한다.
- [ ] 의료 진단/안전 보장 표현이 없다.

완료되지 않은 항목은 owner/date/reason이 있는 명시적 waiver 없이는 Done으로 표시하지 않는다.
