---
task: T005
project: cliker
milestone: M1
created: 2026-06-22
status: TODO
tags: [toybox, task]
---

# T005 — Keycap widget + LED ripple/glow effects

## Context
화면 중앙의 단일 대형 키캡이 이 앱의 얼굴이다. 누르는 손맛(짧고 스냅감 있는 눌림
애니메이션)과 LED 빛(글로우 + 탭마다 퍼지는 리플)이 만족감을 만든다. 이 작업은 그
키캡 위젯을 **자기완결적으로** 만든다 — 오디오/햅틱/통계는 모르고, 콜백과 색만 받는다.
T006이 이 위젯을 실제 서비스에 연결한다.

## Scope — what to build
- `lib/widgets/led_ripple.dart` — `LedRipple` (재사용 가능): 탭 지점에서 바깥으로
  퍼지며 사라지는 링/버스트. `ledColor`로 그려지고 한 번 재생 후 스스로 제거되는 단발 애니메이션.
- `lib/widgets/keycap.dart` — `Keycap` (StatefulWidget):
  - Props: `required Color ledColor`, `String label`(기본 빈/글리프 가능), `VoidCallback? onPressDown`, `VoidCallback? onPressUp`.
  - 비주얼: 입체감 있는 키캡 — 윗면(`AppColors.keycapTop` 그라데이션) + 베벨 모서리
    (`keycapBase`/`keycapEdge`), 중앙 라벨 텍스트, 키캡 둘레 `ledColor` 글로우(BoxShadow/RadialGradient).
  - 인터랙션: `GestureDetector`(onTapDown/onTapUp/onTapCancel)로 눌림 처리 —
    누르면 `AnimationController`로 빠르게(다운 ~60ms) scale↓ + 살짝 아래로 이동(눌림 트래블),
    떼면(업 ~90ms) 스냅 복귀. 글로우는 눌림 시 강해짐.
  - 매 누름마다 키캡 위에 `LedRipple` 1개를 띄우고 애니메이션 종료 시 제거(누수 없음).
  - `onPressDown`/`onPressUp`을 각 1회 호출.
- 모든 색은 props/`AppColors`에서만 (하드코딩 hex 금지). LED 모드(rgbCycle/reactive)는 M2 — 여기선 `ledColor` 솔리드 글로우 + 리플만.

## Out of scope
- 오디오/햅틱/통계/설정 연결 (T006), 스위치 선택 UI (T006).
- LED 모드 전환/색상 피커 (M2 T007). main.dart 와이어링.

## Acceptance criteria (QA verifies each)
- [ ] AC1: `Keycap(ledColor: AppColors.neonCyan, label: 'A')`가 `appTheme()` 하에서 에러 없이 렌더되고 전달한 `Key`를 존중 — 위젯 테스트.
- [ ] AC2: tapDown 제스처에서 `onPressDown`이 정확히 1회, tapUp에서 `onPressUp`이 1회 호출되고, 누름 중 키캡이 "눌림" 시각 상태로 전환됨(예: 내부 `Transform`/`AnimatedScale`의 scale이 1.0 미만 또는 테스트용 Key로 확인 가능한 상태) — `tester.startGesture` 위젯 테스트.
- [ ] AC3: 한 번 누를 때마다 `LedRipple` 1개가 추가되고, 리플 애니메이션 지속시간 경과(`tester.pump(duration)`) 후 트리에서 제거됨(누수 없음) — 위젯 테스트.
- [ ] AC4: 골든 테스트가 (a) 미눌림 Keycap, (b) 눌림 유지 상태 Keycap을 dark 테마 + `neonCyan`로 렌더하고 통과 — `flutter test`로 재현(증거에 골든 png 경로/결과).
- [ ] AC5: `flutter analyze` → "No issues found!", `dart format --set-exit-if-changed .` → 0.

## Test plan — which pyramid layers apply
- Format / Analyze: required
- Unit: N/A: 로직이 위젯 상태에 종속(콜백/애니메이션) — 위젯 테스트로 커버
- Widget: required (AC1–AC3)
- Golden: required (AC4 — 키캡은 핵심 시각 표면)
- Integration: N/A: 단일 위젯, 플로우 없음
- Build: N/A: 앱 엔트리포인트 변경 없음 (위젯은 위젯/골든 테스트로 검증)
- Runtime smoke: N/A: 실행 화면은 T006

## Evidence
- Dev evidence:  docs/tasks/T005/evidence/dev/
- QA evidence:   docs/tasks/T005/evidence/qa/
