# Roadmap

## Phase 1 — Squat Rep Count

- Flutter Android/iOS camera/permission/lifecycle
- on-device pose + skeleton/alignment
- angle/EMA/squat-v1/count/result
- local-first
- Gate: 10회→9~11, pose ≥10 FPS, raw frame request 0

## Phase 2 — Deterministic Pose Feedback

- shallow/tempo/setup cues
- validated form score version
- Supabase Auth/history/RLS
- voice/haptic feedback usability validation

## Phase 3 — Exercise Expansion

- push-up, lunge, plank; 이후 deadlift research
- shared PoseDetectionService and analyzer registry
- exercise-specific validation datasets

## Phase 4 — AI Personalized Coach

- Edge Function structured metrics feedback
- prompt eval/safety/localization
- opt-in longitudinal trends

## Phase 5 — Ecosystem

- subscription
- opt-in social
- Apple Health/Health Connect with minimum permissions
- export/portability and store-scale operations

각 phase는 이전 품질/privacy gate를 통과한 뒤 시작한다. raw video cloud analysis, injury diagnosis, safety guarantee는 roadmap에 포함하지 않는다.
