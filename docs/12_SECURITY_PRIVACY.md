# Mobile Security and Privacy

## Data Boundary

```text
Camera Frame → On-device Pose SDK → Pose Landmarks → Aggregate Metrics
```

기본 저장 금지:

- camera video/photo/raw frame
- raw CameraImage plane
- screenshot/recording
- raw landmark time series

저장 허용:

- rep count, duration
- aggregate angle/tempo/confidence
- versioned nullable form score
- workout session metadata와 AI feedback

사용자 문구:

> 카메라 영상은 자세 분석을 위해 기기에서 처리되며 기본적으로 서버에 저장되지 않습니다.

## Mobile Secrets

Flutter 앱 포함 금지:

- `SUPABASE_SERVICE_ROLE_KEY`
- LLM/provider API key
- backend admin/private key
- signing private key

앱에는 Supabase URL과 publishable key만 허용한다. publishable key는 RLS를 대체하지 않는다. LLM은 Edge Function secret을 사용한다. build-time define/obfuscation은 secret protection이 아니다.

민감한 session token은 Supabase SDK가 권장하는 secure storage 전략을 사용한다. shared_preferences에 private token을 직접 저장하지 않는다.

## Permissions

### Android

최소 permission:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
```

audio, location, storage/media library 권한은 MVP에서 요청하지 않는다. target/min SDK는 camera/ML Kit 공식 요구와 store 정책을 구현 시 확정한다.

### iOS

`Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>FormAI uses the camera to analyze your exercise movement in real time.</string>
```

한국어 localization:

```text
FormAI는 운동 동작을 실시간으로 분석하기 위해 카메라를 사용합니다.
영상은 기본적으로 서버에 저장되지 않습니다.
```

microphone/photo library usage description은 기능이 없으므로 추가하지 않는다.

## Permission UX

- OS prompt 전에 in-app rationale.
- denied는 재시도 설명, permanently denied는 settings deep link.
- prompt 반복/강제 금지.
- permission revoke 후 resume 시 재검사.
- 권한 없이 제한된 Home/Privacy 화면은 볼 수 있다.

## Authentication and RLS

- Supabase Auth JWT의 `auth.uid()`가 owner source다.
- client가 전송한 user ID를 권한 근거로 쓰지 않는다.
- profiles/session/reps/feedback에 RLS를 적용하고 cross-user access를 테스트한다.
- 다른 user resource와 없는 resource는 같은 not-found 의미로 처리한다.
- service role을 쓰는 Edge Function도 JWT와 session ownership을 먼저 검증한다.

## Network and Abuse

- HTTPS only, certificate validation 우회 금지.
- feedback/session mutation에 user/IP rate limit과 idempotency.
- strict allowlist schema와 payload size limit.
- user-provided URL fetch 없음; LLM endpoint 고정.
- offline save/retry가 중복 session을 만들지 않게 client_session_id 사용.

## Logging

허용: stable error code, app/build version, OS/device class, latency/FPS aggregate, request ID.

금지: camera bytes, image, landmarks, access token, secret, LLM raw credentials, precise biometric trace. crash reporting breadcrumb도 같은 allowlist를 사용한다.

## Data Retention

| Data | Default |
|---|---|
| raw frame | 처리 직후 0 retention |
| local workout | user deletion까지; 정책 확정 필요 |
| cloud metrics | account/session deletion까지; 목표 기간 법률 검토 |
| AI feedback | parent session과 함께 삭제 |
| sanitized server log | 목표 30일 |

Settings에서 local data와 cloud account data 삭제 경로를 제공한다. backup 삭제 SLA와 지역별 privacy 법률은 release 전 검토한다.

## Dependency and Supply Chain

- pub package publisher, native SDK, license, privacy notice, maintenance를 검토한다.
- `pubspec.lock`을 commit하고 dependency audit/update cadence를 둔다.
- ML SDK/model version을 기록한다.
- production signing credential은 CI secret store/OS keychain에서 관리하고 repository에 두지 않는다.

## Threat Tests

1. 다른 사용자 session 조회/수정/삭제 → 거부.
2. payload에 frame/base64/landmarks 추가 → validation 거부.
3. background 후 camera indicator 지속 → 실패로 처리.
4. 앱 bundle string scan에서 server secret → 0건.
5. AI HTML/prompt injection → plain text/schema validation.
6. network proxy 검사에서 image/video/frame upload → 0건.

## Non-medical Safety

FormAI는 의료기기가 아니다. 통증·부상 여부를 판단하거나 안전을 보장하지 않는다. 사용자가 통증을 알리면 운동 중단과 적절한 의료 전문가 상담을 안내한다.
