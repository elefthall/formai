# Flutter Coding Rules

## Scope

MVP 전 불필요한 기능을 추가하지 않는다. Camera → Pose → Angle → State → Count → Result 순서를 지킨다.

## Dart

- sound null safety와 analyzer strict rule을 사용한다.
- `dynamic`, `!`, unchecked cast, ignored lint를 최소화하고 경계에서 검증한다.
- immutable model, const constructor, enum/sealed state를 우선한다.
- 단위를 이름에 적는다.
- pure function이 global clock/random/singleton을 읽지 않게 한다.

## Architecture

- domain은 Dart core/math 외 Flutter, Riverpod, camera, ML Kit, Supabase를 import하지 않는다.
- SDK type은 infrastructure 밖으로 노출하지 않는다.
- Widget은 Pose SDK/angle/state machine을 호출하지 않는다.
- provider는 dependency injection/lifecycle, analyzer는 판단을 담당한다.
- repository DTO와 domain entity mapping을 분리한다.
- 새 운동은 analyzer interface/registry로 추가한다.

## Camera and Performance

- inference single-flight; queue 금지; frame drop 허용.
- CameraImage를 field/list/cache에 저장하지 않는다.
- frame마다 전체 Widget tree를 rebuild하지 않는다.
- CameraController/detector/stream/subscription을 idempotently close/dispose한다.
- lifecycle, permission, orientation을 명시적 state로 처리한다.
- optimization은 profiler 측정과 함께 한다.

## Naming

- type/widget: PascalCase; member/function/file: lowerCamelCase/snake_case.
- boolean: is/has/can/should.
- event: `repCompleted`처럼 완료 의미.
- `angleDeg`, `durationMs`, `confidence`처럼 의미·단위를 드러낸다.

## Security

- raw media/landmark trace를 network/storage/log에 보내지 않는다.
- service role/LLM/admin secret을 app/env asset에 넣지 않는다.
- publishable key는 RLS와 함께만 사용한다.
- 민감 token은 secure storage 정책을 따른다.
- analytics/log field allowlist를 사용한다.

## Testing

- algorithm 변경에는 regression fixture를 포함한다.
- threshold 변경은 validation 근거, analyzer version, boundary test를 갱신한다.
- camera/pose는 mock interface로 integration test한다.
- bug fix에는 재현 test가 필수다.
- 완료 전 format/analyze/test/build를 수행한다.

## Dependencies

- 구현 시 Flutter stable과 공식 pub.dev/platform docs를 확인한다.
- publisher, maintenance, min OS, native SDK, privacy, license를 검토한다.
- app의 `pubspec.lock`을 commit한다.
- codegen은 boilerplate 감소 효과가 분명할 때만 도입한다.

## Change Discipline

- 기존 사용자 변경을 되돌리지 않는다.
- 기능과 source-of-truth 문서를 같은 change에서 갱신한다.
- 인증/AI/추가 운동/refactor를 요청 없이 앞당기지 않는다.
- emulator test를 실제 camera validation으로 표현하지 않는다.
