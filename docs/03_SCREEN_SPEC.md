# Screen Specification

Analytics에는 frame, landmark, image, 자유 텍스트를 포함하지 않는다.

| ID | Name / Route | Purpose | Components / CTA | User Action | State / Loading / Empty / Error | Navigation | Analytics |
|---|---|---|---|---|---|---|---|
| S01 | Splash `/` | 초기화 | logo/progress | wait | loading; init failure | S02/S05 | `app_open` |
| S02 | Onboarding 1 `/onboarding/value` | 가치 설명 | illustration/다음 | next/skip | page 1; asset fallback | S03/S04 | `onboarding_1` |
| S03 | Onboarding 2 `/onboarding/privacy` | privacy 설명 | shield/시작 | next/back | page 2; persistence error non-blocking | S04 | `onboarding_done` |
| S04 | Camera Permission `/permission/camera` | 권한 rationale | permission card/허용 | allow/settings | idle/requesting/granted; denied/permanent/no camera | S05/S08 | `camera_permission_result` |
| S05 | Home `/home` | 운동 진입 | start/recent/nav | start/history/settings | loading; no recent; local error | S06/S12/S14 | `home_viewed` |
| S06 | Exercise Selection `/exercises` | 종목 선택 | cards/스쿼트 | select | squat enabled; future disabled | S07 | `exercise_selected` |
| S07 | Setup `/workout/squat/setup` | 기기·측면 안내 | checklist/정렬 확인 | confirm/back | checklist; orientation warning | S08 | `setup_viewed` |
| S08 | Alignment `/workout/squat/alignment` | pose 사전 검증 | preview/painter/시작 | retry/flip/start | camera/model loading; no pose/partial/low confidence | S09 | `alignment_ready` |
| S09 | Active `/workout/squat/active` | count·feedback | preview/overlay/counter | squat/pause/finish | active/tracking paused; detector/camera error | S10/S11 | `workout_started`, `rep_counted` |
| S10 | Pause `/workout/squat/pause` | 안전 중단 | summary/계속 | resume/finish | paused; camera reinit loading/error | S08/S11 | `workout_paused` |
| S11 | Result `/workout/result` | 결과·저장 | metrics/완료 | save/home | local/syncing/saved; optional empty; sync error | S05/S12 | `workout_completed` |
| S12 | History `/history` | 기록 목록 | list/filter | scroll/select | loading; empty; offline/auth error | S13 | `history_viewed` |
| S13 | Detail `/history/:id` | 세션 상세 | metrics/뒤로 | view/retry | loading; feedback empty; not found | S12 | `detail_viewed` |
| S14 | Settings `/settings` | account/privacy/preferences | settings/delete | sign/delete/set | loading; anonymous; save/delete error | S05 | `settings_viewed` |

## Common Rules

- permission은 사용자 CTA 이후에만 요청한다.
- alignment가 안정화되기 전 Active 진입을 막는다.
- Active에서 system back은 종료 확인을 표시한다.
- background는 auto-pause하고 alignment를 거쳐 resume한다.
- cloud history/profile은 P1이다.
- 상태는 색상과 text/semantics를 함께 사용하며 touch target은 48dp다.
