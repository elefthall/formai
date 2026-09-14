# API Contract

Flutter는 Supabase SDK를 repository adapter에서 사용한다. 아래 REST contract는 Edge Function/향후 API 경계의 canonical 의미다. domain/application은 HTTP 또는 Supabase type을 알지 않는다.

## Conventions

- HTTPS JSON, UTC ISO-8601, UUID.
- Supabase access token으로 인증하고 owner는 JWT에서 결정한다.
- request body strict validation, ≤64KB, metrics ≤16KB.
- raw frame/video/photo/landmark/base64 key는 거부한다.
- error: `{"error":{"code":"VALIDATION_ERROR","message":"요청 값을 확인해 주세요.","request_id":"..."}}`

## POST /workout-sessions

- Purpose: active session 생성.
- Request:

```json
{
  "client_session_id": "uuid",
  "exercise": "squat",
  "started_at": "2026-09-11T05:00:00Z",
  "analyzer_version": "squat-v1"
}
```

- Validation: active exercise, timestamp ±10m, UUID, analyzer version allowlist.
- Response `201`: `{"data":{"id":"uuid","status":"active","total_reps":0}}`.
- 동일 client session은 idempotent `200`. Errors: 401, 409 inactive, 422.

## PATCH /workout-sessions/{id}

- Purpose: active session을 completed/abandoned로 종결.
- Request:

```json
{
  "status": "completed",
  "ended_at": "2026-09-11T05:04:32Z",
  "duration_seconds": 272,
  "total_reps": 20,
  "valid_rep_count": 17,
  "shallow_rep_count": 3,
  "avg_rep_duration_ms": 2860,
  "avg_bottom_knee_angle": 101,
  "average_pose_confidence": 0.88,
  "metrics": {"tracking_loss_count": 2}
}
```

- Validation: owner; active only; values finite/range-consistent; metrics allowlist.
- Response `200` complete DTO.
- Errors: 401, 404 (other owner 포함), 409 already finalized, 422 inconsistent.

## GET /workout-sessions

- Purpose: 내 history.
- Query: `exercise=squat&status=completed&limit=20&cursor=opaque`; limit 1..50.
- Response:

```json
{
  "data": [{
    "id": "uuid",
    "exercise": "squat",
    "started_at": "2026-09-11T05:00:00Z",
    "ended_at": "2026-09-11T05:04:32Z",
    "duration_seconds": 272,
    "total_reps": 20,
    "form_score": null
  }],
  "page": {"next_cursor": null, "has_more": false}
}
```

- Order: started_at desc, id desc. Status 200; invalid cursor 400; auth 401.

## GET /workout-sessions/{id}

- Purpose: own session, optional reps/feedback.
- Response `200`:

```json
{
  "data": {
    "session": {"id":"uuid","exercise":"squat","total_reps":20},
    "reps": [{"rep_number":1,"duration_ms":2860,"min_knee_angle":101}],
    "feedback": null
  }
}
```

- Validation: UUID + ownership. Missing/other owner 모두 404.

## POST /workout-sessions/{id}/feedback

- Purpose: completed DB metrics로 Edge Function이 AI feedback 생성.
- Request: `{"locale":"ko-KR","regenerate":false}`.
- Client-supplied metrics는 받거나 신뢰하지 않는다.
- Validation: owner, completed, reps >0, locale allowlist, rate limit.
- Response `200/201`:

```json
{
  "data": {
    "summary": "...",
    "strengths": [],
    "improvements": [],
    "next_action": "...",
    "confidence": "low"
  }
}
```

- Errors: 404, 409 not completed/already exists, 422 inconsistent, 429, 502 provider.

## Common Status Codes

| Code | Meaning |
|---:|---|
| 200/201 | success |
| 400 | malformed request |
| 401 | unauthenticated |
| 404 | unavailable resource |
| 409 | state/idempotency conflict |
| 413 | too large |
| 422 | semantic inconsistency |
| 429 | rate limited |
| 500/502/503 | server/dependency failure |

Responses use `Cache-Control: private, no-store`. Logs contain request ID, route, status, latency only; tokens and biometric-like data are redacted.
