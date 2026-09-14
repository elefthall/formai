# Weekend Mobile MVP Plan

## Guardrail

Camera → Pose → PoseFrame → Angle → EMA → State Machine → Rep Count → UI → Result 순서다. Supabase/Auth/History/AI는 weekend P0가 아니다.

## Day 0 — Readiness

- [ ] Flutter stable/Dart/Android Studio/Xcode version 기록
- [ ] 실제 Android/iPhone 개발 기기 확보
- [ ] camera/ML Kit 공식 min OS와 image format 확인
- [ ] package versions와 lockfile 고정
- [ ] skeleton Flutter project와 flavor/env 정책 확정

## Day 1 — Camera + Pose

- [ ] feature-first folder와 domain interfaces
- [ ] Riverpod/go_router 최소 app shell
- [ ] Android CAMERA/INTERNET, iOS camera usage localization
- [ ] rationale/denied/permanent permission UX
- [ ] CameraController preview와 lens selection
- [ ] lifecycle observer/background release/resume
- [ ] PoseDetectionService interface + ML Kit adapter
- [ ] sensor rotation/image format mapping
- [ ] 10~15 FPS single-flight/drop
- [ ] PoseFrame mapping/validation
- [ ] Camera Alignment + CustomPainter skeleton
- [ ] camera/detector dispose tests

Acceptance: 실제 Android와 iPhone에서 preview/skeleton이 동작하고 background에서 camera indicator가 꺼지며 network에 frame이 없다.

## Day 2 — Count + Result

- [ ] pure Dart angle + EMA
- [ ] squat-v1 config/state/event
- [ ] full-cycle, ROM, cooldown, tracking reset
- [ ] side selection 안정화
- [ ] rep counter, deterministic cues
- [ ] Active/Pause/Resume/Result UI
- [ ] local result fallback
- [ ] unit/widget/integration tests
- [ ] 10-rep manual validation
- [ ] analyze/build/privacy checks

Acceptance: normal fixture 1, shallow 0, noise 1, pose-loss 0; real device 10회가 9~11 범위.

## Cut Line

AI Coach → cloud History/Auth → form score → animation polish → 추가 운동 순으로 제외한다. skeleton과 lifecycle correctness는 유지한다.

## Demo

1. rationale 후 camera 승인.
2. 측면 전신 alignment와 skeleton.
3. shallow squat이 count되지 않음.
4. 정상 3회 count.
5. background/resume 후 alignment 재확인.
6. finish와 local result.
