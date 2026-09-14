# User Flow

## Primary Flow

```mermaid
flowchart TD
  A[App Launch] --> B[Splash]
  B --> C{First launch?}
  C -- Yes --> D[Onboarding 1]
  D --> E[Onboarding 2]
  E --> F[Camera Permission]
  C -- No --> G[Home]
  F -->|granted| G
  F -->|denied| F1[Settings guidance]
  F1 --> F
  G --> H[Exercise Selection]
  H --> I[Camera Setup Guide]
  I --> J[Camera Alignment]
  J -->|valid| K[Active Workout]
  J -->|invalid| J1[Adjustment guidance]
  J1 --> J
  K -->|pause| L[Pause Workout]
  L -->|resume| J
  K -->|finish| M[Workout Result]
  L -->|finish| M
  M --> N[History]
  N --> O[Detail]
```

## Runtime Flow

```mermaid
flowchart LR
  CameraImage --> SDK[PoseDetectionService]
  SDK --> Normalize[Rotation + normalization]
  Normalize --> PoseFrame
  PoseFrame --> Validity
  Validity --> EMA
  EMA --> SquatAnalyzer
  SquatAnalyzer --> Controller[Riverpod Controller]
  Controller --> UI
  Controller -->|aggregates| Repository
```

## Lifecycle Flow

```mermaid
stateDiagram-v2
  [*] --> idle
  idle --> initializing: explicit start
  initializing --> streaming: resources ready
  streaming --> suspended: inactive / paused / lock / call
  suspended --> initializing: resume
  streaming --> idle: finish / leave
  initializing --> error: denied / unavailable
  error --> initializing: retry
```

## Exceptional Rules

- permanently denied는 settings CTA를 제공하고 prompt loop를 만들지 않는다.
- interruption/background는 stream과 inference를 중단하고 incomplete rep을 취소한다.
- resume은 permission 재검사 후 alignment부터 시작한다.
- invalid pose에서는 count를 중지한다.
- save failure에도 local result를 유지한다.
