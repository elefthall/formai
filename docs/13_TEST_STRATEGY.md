# Flutter Test Strategy

## Quality Gates

PR: format → `flutter analyze` → unit/widget test. Release candidate: integration tests, Android/iOS build, privacy proxy, 실제 Android/iPhone Pose validation.

## Unit Tests

- `calculateAngle`: 0/90/180, clamp, zero vector, NaN/Infinity.
- EMA: first, alpha 0.35, sequence, invalid skip, reset.
- pose validation: missing/partial/confidence exact 0.5/out-of-frame/non-finite.
- side selection: stable choice, mid-rep switch 금지.
- state machine/counter: full, shallow, noise, bounce, cooldown, pose loss, pause.
- form score: Phase 2 전에는 nullable; 존재하지 않는 score 생성 금지.
- coordinate transform: Android/iOS rotation, front mirror, aspect crop.

Core fixtures:

| Case | Sequence | Expected |
|---|---|---|
| normal | 170,150,125,95,120,145,165 | rep 1 |
| shallow | 170,145,130,125,145,170 | rep 0 |
| noise | 170,150,110,103,107,101,105,125,150,165 | rep 1 |
| lost | standing,descending,missing,missing,standing | rep 0 |

domain branch coverage 목표 ≥95%, 전체 신규 line ≥80%. critical invariant를 coverage 숫자보다 우선한다.

## Widget Tests

- permission rationale → CTA state.
- alignment loading/valid/invalid copy.
- large counter와 semantic label.
- text scale 1.0/1.3/2.0에서 overflow 없음.
- pause/result/error 화면.
- Provider override로 SDK 없이 상태를 구동한다.

## Integration Tests

```text
FakePoseDetectionService
→ timestamped PoseFrame sequence
→ SquatAnalyzer
→ WorkoutController
→ Riverpod state
→ counter/result
```

camera service도 fake로 교체해 permission states, initialization failure, stream stop, dispose/close idempotency, background/resume, single-flight/drop을 검증한다.

## E2E

```text
Launch → Home → Start → Squat → Permission → Alignment
→ Workout → Rep increases → Stop → Result → History
```

- automated integration_test는 fake camera/pose로 deterministic하게 수행.
- 실제 camera E2E는 실기기 manual/instrumented test.
- Android Emulator만으로 Pose 기능 완료 판정 금지.

## Real-device Matrix

최소:

- Android 저/중/고성능 3종 또는 가능한 대표 2종
- iPhone 구형 지원 기준 1종 + 최신 1종
- front/rear camera, portrait/landscape
- background, lock, 전화 interruption, permission revoke
- 밝음/어두움, 2~3m, 다양한 체형/의상

각 platform에서 5명 × 정상 10회, shallow negative를 목표로 하고 사람별 split으로 threshold를 튜닝한다.

## Performance

| Metric | Target |
|---|---:|
| Preview | ≥24 FPS |
| Pose inference | ≥10 FPS |
| Rep feedback | <300ms p95 |
| Concurrent inference | exactly 1 |
| CameraImage retention | no queue |
| 15-min memory | no unbounded growth |

DevTools/native profiler로 CPU/GPU/memory/thermal throttling을 기록한다. 느릴 때 frame drop은 허용하되 backlog는 허용하지 않는다.

## Privacy and Security Tests

- proxy/network instrumentation: raw media request 0.
- bundle/string scan: service role/LLM secret 0.
- RLS cross-user SELECT/INSERT/UPDATE/DELETE negative tests.
- log capture에 frame/landmark/token이 없음.
- background/route leave 후 camera indicator가 꺼짐.
- malformed metrics와 AI output schema rejection.

## Build Compatibility

- Android debug/release smoke, ABI/minSdk/ProGuard-R8 검증.
- iOS simulator build + `flutter build ios --no-codesign`, 실제 signed device run.
- ML native framework size, architecture, offline availability 검증.
- Flutter stable upgrade는 별도 PR에서 전체 matrix를 재실행한다.
