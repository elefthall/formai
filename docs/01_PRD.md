# FormAI Mobile MVP PRD

## Document Control

- Platform: Flutter Android/iOS
- Stage: implementation-ready specification
- MVP exercise: squat
- Success: controlled 10 reps → detected 9~11

## Background and Problem

혼자 운동하는 초보자는 자세와 횟수를 동시에 관리하기 어렵다. 기존 콘텐츠 앱은 실제 움직임을 확인하지 않는다. FormAI는 스마트폰 camera와 on-device Pose Detection으로 전체 스쿼트 사이클을 측정한다.

## Goals

1. 명시적 동의 후 camera preview를 시작한다.
2. 한 사람의 shoulder/hip/knee/ankle을 기기에서 10~15 FPS로 추적한다.
3. pure Dart knee angle과 EMA를 계산한다.
4. standing → bottom → standing 전체 사이클만 센다.
5. 큰 counter와 rule-based 안내를 300ms 이내 제공한다.
6. 결과를 로컬에 유지하고 인증 사용자는 aggregate metrics만 저장한다.
7. background/interruption에서 모든 resource를 안전하게 해제한다.

## Non-goals

- 웹앱, desktop, wearable
- 의료·부상 진단, 안전 보장
- raw media upload/recording
- 실시간 LLM
- multi-person, 3D biomechanics, 공인 form score
- MVP의 추가 운동, subscription, social

## Personas

- 지민: 스마트폰 홈트 입문자. 자세·횟수 확신과 영상 privacy가 필요하다.
- 민수: 헬스장 초보자. PT 부담 없이 세트 기록을 원한다.

## User Stories

- 카메라 사용 이유를 읽은 뒤 OS 권한을 결정한다.
- 전신이 프레임에 들어왔는지 운동 전에 확인한다.
- 운동 중 횟수와 준비/내려가기/바닥/올라오기 상태를 본다.
- pose가 불안정하면 오카운트 대신 조정 안내를 받는다.
- 앱 background에서 camera가 중지되기를 기대한다.
- 종료 후 결과를 보고 자신의 기록만 조회한다.

## Functional Requirements

| ID | Requirement | Acceptance | Priority |
|---|---|---|---|
| FR-01 | Camera permission | rationale 후 OS prompt; denied/permanent 구분 | P0 |
| FR-02 | Lifecycle | preview ≥24 FPS 목표; background release | P0 |
| FR-03 | On-device pose | required 8 landmarks, confidence ≥0.5 | P0 |
| FR-04 | Alignment | missing/partial/out-of-frame 안내 | P0 |
| FR-05 | Angle/EMA | 0~180°, alpha 0.35 pure Dart | P0 |
| FR-06 | State machine | standing 155°, bottom 105°, ROM 45°, cooldown 400ms | P0 |
| FR-07 | Rep UI | full cycle only; latency <300ms | P0 |
| FR-08 | Controls | start, pause, resume, finish | P0 |
| FR-09 | Result | reps, duration, aggregates; local fallback | P0 |
| FR-10 | History/Auth | own records with Auth/RLS | P1 |
| FR-11 | AI feedback | Edge Function; aggregates only | P2 |

## Non-functional Requirements

- Preview ≥24 FPS, pose ≥10 FPS, feedback <300ms on target devices.
- CameraImage를 보관하지 않고 single-flight inference와 frame drop을 사용한다.
- 큰 counter, text scaling, semantics, 48dp target을 지원한다.
- raw media zero network/storage, sanitized logs.
- feature-first, Riverpod, repository/SDK abstraction, pure domain tests.

## KPI

| KPI | Target |
|---|---:|
| Controlled count | 10 → 9~11 |
| Accuracy | ≥90% |
| Standing false positive | 0/60s |
| Pose inference | ≥10 FPS |
| Preview | ≥24 FPS |
| Feedback latency | <300ms p95 |
| Raw-frame request | 0 |

## Scope and Risks

순서는 Camera → Pose → PoseFrame → Angle → EMA → State → Count → UI → Result다. P0 실기기 검증 전 Supabase/AI/추가 운동을 구현하지 않는다. ML Kit platform 차이, sensor rotation, 발열, 2D 왜곡, lifecycle interruption, threshold overfit을 real-device spike와 adapter/fixture로 완화한다.

초기 threshold, 최소 OS 버전, camera 방향 정책은 모두 **추가 검증 필요**다.
