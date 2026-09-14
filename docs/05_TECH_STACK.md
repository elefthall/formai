# Flutter Technology Stack

버전은 구현 시작일의 Flutter stable/Dart compatibility와 공식 pub.dev 문서를 확인해 exact lockfile로 고정한다. 이 문서는 제품 선택 기준이며 임의 최신 버전을 강제하지 않는다.

| Area | Choice | Why | Alternative | Trade-off |
|---|---|---|---|---|
| UI | Flutter | Android/iOS 단일 코드, camera overlay/CustomPainter | native Swift/Kotlin | platform plugin 이슈는 native 지식 필요 |
| Language | Dart | sound null safety, testable pure domain | Kotlin Multiplatform | Flutter 생태계 선택과 일치 |
| State | Riverpod | DI, async lifecycle, test override | Bloc, Provider | provider lifecycle 설계 필요 |
| Router | go_router | declarative navigation, redirect | Navigator 직접 사용 | 간단 MVP에는 추가 dependency |
| Camera | camera | Flutter team 생태계, image stream | camerawesome/native | platform lifecycle를 앱이 책임 |
| Pose MVP | Google ML Kit Pose Detection | Flutter 생산성, on-device, mobile 최적화 | MediaPipe native | plugin 지원 OS/format 검증 필요 |
| Backend | Supabase Flutter | Auth, PostgreSQL, RLS, realtime 필요 시 | Firebase/custom API | offline/error/RLS 설계 필요 |
| Edge | Supabase Edge Functions | secret server boundary, AI gateway | custom server | vendor/runtime 제약 |
| Settings | shared_preferences | 작은 비민감 설정 | Hive/Isar | workout 대량 데이터에는 부적합 |
| Test | flutter_test + mocktail | SDK 기본 + typed mocks | Mockito | mocktail 등록/fixture 관리 |
| Models | plain immutable Dart first | MVP codegen 부담 최소 | freezed/json_serializable | boilerplate가 늘면 codegen 도입 |

## Pose SDK Decision

MVP는 Google ML Kit Pose Detection adapter를 먼저 spike한다.

Go 조건:

- Android/iOS 양쪽 공식 지원 범위 충족
- required landmarks와 likelihood 제공
- camera image format/rotation 변환 가능
- 실제 target device에서 ≥10 inference FPS
- resource close와 offline/on-device 처리 확인

조건을 만족하지 못하면 동일 `PoseDetectionService` interface 아래 MediaPipe Pose Landmarker native integration을 비교한다. domain/application은 SDK 교체로 바뀌지 않아야 한다.

## Camera Direction

setup UX상 후면 카메라를 기본 후보로 검토한다(고정 촬영 품질). 사용자가 혼자 정렬하기 어려운 문제 때문에 전면 카메라도 제공한다. mirror는 preview에만 적용하고 normalized landmark 의미는 adapter가 보정한다. 기본값은 real-device usability test로 **추가 검증 필요**다.

## Local Persistence

- onboarding 완료, 선호 camera 등 작은 설정: shared_preferences.
- workout result P0: in-memory + 최소 local durable repository를 구현 spike에서 결정.
- 다량 history/offline sync가 필요해질 때 Isar/Hive/SQLite를 ADR로 선택한다.
- token/민감 credential은 shared_preferences에 평문 저장하지 않는다.

## Dependency Policy

- package의 publisher, maintenance, platform requirements, privacy, transitive native SDK를 검토한다.
- caret 범위와 `pubspec.lock`을 함께 관리하고 app repository에서는 lockfile을 commit한다.
- 새 dependency는 기존 Flutter/Dart API로 해결할 수 없는 이유를 기록한다.
- ML model/SDK version과 analyzer version은 별개로 기록한다.
