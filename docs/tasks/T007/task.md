---
task: T007
project: cliker
milestone: M2
created: 2026-06-22
status: TODO
tags: [toybox, task]
---

# T007 — Settings & customization (LED modes, color, sound/haptic toggles)

## Context
M1은 기본값으로 동작한다(사운드/햅틱 ON, LED=ripple, 색=neonCyan). M2는 사용자가
자기 취향대로 만들 수 있게 한다: LED 색·효과 모드 선택, 사운드·햅틱 토글. 상태/영구저장은
T003에서 이미 끝났으므로(`settingsProvider`), 이 작업은 (1) 설정 UI와 (2) LED 효과 모드의
실제 시각 구현을 더한다.

## Scope — what to build
- 설정 진입점: `HomeScreen`에 설정 아이콘 버튼(AppBar 또는 코너) → `SettingsSheet`(modal bottom sheet) 오픈.
- `lib/screens/settings_sheet.dart` (또는 widgets/) — `settingsProvider`에 바인딩:
  - 사운드 토글(`setSound`), 햅틱 토글(`setHaptic`).
  - LED 색 선택: `AppColors.ledPalette` 6색 스와치 + 현재 선택 표시 → `setLedColor(argb)`.
  - LED 모드 선택: `LedMode`(ripple/solid/rgbCycle/reactive) 세그먼트/칩 → `setLedMode`.
  - 모두 즉시 반영 + 영구(이미 notifier가 prefs 저장).
- LED 모드 시각 구현 — `Keycap`(또는 효과 레이어)이 `ledMode`를 받아 동작:
  - `solid`: 고정 `ledColor` 글로우(현 동작).
  - `ripple`: 누름마다 리플(현 동작, T005).
  - `rgbCycle`: 글로우/리플 색이 시간에 따라 hue 순환(애니메이션, 무한 반복, 누름과 무관하게 또는 누름 시 색 추출).
  - `reactive`: 글로우 세기가 최근 클릭 활동(예: 세션 CPM 또는 직전 누름 후 감쇠)에 반응해 밝아짐/숨쉼.
  - 기존 `Keycap` API 호환 유지(`ledColor`/`label`/`onPressDown`/`onPressUp`), `ledMode`는 새 옵션 prop으로 추가(기본 ripple).

## Out of scope
- 통계 패널/리셋 UI (T008). 스위치별 커스텀(스위치는 T006 선택기로 충분).
- 새 패키지 의존성(색 선택은 팔레트 스와치로 충분, 서드파티 컬러피커 불필요).

## Acceptance criteria (QA verifies each)
- [ ] AC1: HomeScreen의 설정 버튼 탭 → SettingsSheet가 열리고 사운드/햅틱 토글, 색 6스와치, 모드 선택이 보인다 — 위젯 테스트.
- [ ] AC2: 사운드 토글 OFF → `settingsProvider.soundEnabled==false`로 반영되고, HomeScreen에서 키캡 누름 시 사운드 재생이 억제됨(Fake로 검증); 햅틱 토글도 동일 — 위젯 테스트(Fake player/haptics 스파이).
- [ ] AC3: 색 스와치(예: neonMagenta) 선택 → `settingsProvider.ledColorArgb`가 그 값으로 바뀌고 Keycap 글로우 색이 갱신; 영구(새 컨테이너에서 유지) — 위젯/단위 테스트.
- [ ] AC4: LED 모드 선택이 `settingsProvider.ledMode`에 반영·영구되고, `rgbCycle`에서 글로우 색이 시간 경과(`tester.pump` 진행)에 따라 변함, `reactive`에서 누름 직후 글로우 세기가 증가 — 위젯 테스트(애니메이션 프레임 어서션).
- [ ] AC5: `flutter analyze` → "No issues found!", `dart format --set-exit-if-changed .` → 0, `flutter test` green.
- [ ] AC6: `flutter build apk --debug` 성공.

## Test plan — which pyramid layers apply
- Format / Analyze: required
- Unit: 색/모드 영구(설정 notifier는 T003에서 검증됨; 여기선 UI 바인딩 중심)
- Widget: required (AC1–AC4, Fake player/haptics + 애니메이션 프레임)
- Golden: 선택 — rgbCycle/reactive는 시간 의존이라 골든 불안정 가능; solid 색 변경 1컷 골든은 가능(권장, N/A 시 사유)
- Integration: N/A: 단일 화면 상호작용 (엔드투엔드는 T006에서 확립)
- Build: required (AC6)
- Runtime smoke: required — 에뮬레이터에서 설정 변경(색/모드/토글)이 실제 반영되는지 1회 확인(스크린샷)

## Evidence
- Dev evidence:  docs/tasks/T007/evidence/dev/
- QA evidence:   docs/tasks/T007/evidence/qa/
