# FormAI Product Overview

## Product Vision

스마트폰을 세워두는 것만으로 누구나 자신의 운동 움직임을 이해하고 혼자서도 일관되게 운동할 수 있게 한다.

## Product Definition

FormAI는 Flutter로 구축하는 Android/iOS 모바일앱이다. camera frame을 기기에서 Pose Detection으로 처리하고 pure Dart 관절각·상태 머신으로 스쿼트 반복을 센다.

## Problem

운동 초보자는 자신의 자세를 객관적으로 보기 어렵고 반복 횟수까지 직접 세어야 한다. 영상 콘텐츠는 개인 수행을 판단하지 않으며, 거울은 시선을 흐트러뜨릴 수 있고 개인 PT는 비용·시간 부담이 있다.

## Target User

- Primary: 집 또는 헬스장에서 혼자 운동하는 경력 0~12개월 초보자
- Secondary: 스마트폰을 고정해 홈트레이닝하는 사용자
- Needs: 자동 기록, 명료한 안내, 낮은 비용, 영상 privacy

## Value Proposition

```text
스마트폰 카메라 → 실제 움직임 측정 → 자동 Rep Count → 자세 정보 → 결과
```

- 별도 wearable 없이 즉시 사용
- 실제 사용자 움직임을 분석
- raw 영상이 기기를 떠나지 않는 privacy-first 구조
- 설명 가능하고 테스트 가능한 deterministic 판정

## MVP

스쿼트 한 종목, 단일 사용자, 통제된 촬영 조건을 지원한다. 정상 10회에서 9~11회 인식(목표 정확도 ≥90%)이 핵심 gate다.

## Differentiation

Freeletics, Peloton, Nike Training Club의 명료한 workout UX를 참고하되 콘텐츠가 아니라 on-device Computer Vision 기반 실제 동작 분석을 차별점으로 삼는다.

## Non-medical Positioning

측정과 피드백은 운동 참고 정보다. 의료 진단, 부상 판정, 치료 조언 또는 안전 보장이 아니다.
