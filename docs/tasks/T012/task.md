---
task: T012
project: cliker
milestone: M4
created: 2026-06-23
status: TODO
tags: [toybox, task]
---

# T012 — 스위치 11종 확장 + UI 개편 (키캡·통계·선택기)

## Context
사용자 요청: 체리 MX 라인업 전체(11종)를 지원하고, UI를 개편한다. 통계는 2개만(전체
클릭수·RPM), 키캡을 "진짜 키캡 모양 + 확실한 눌림 효과"로, 스위치 선택기는 11종을
가로 스크롤로. 사운드 품질 튜닝은 이번 스코프 아님(각 축이 동작하는 합성음만 있으면 됨).

기존 코드: `AppColors`(theme), `SwitchCatalog`(domain), `gen_sounds.py`(합성),
`settingsProvider`/`statsProvider`(state), `Keycap`/`LedRipple`(widgets),
`StatsPanel`/`SettingsSheet`, `HomeScreen`, `ClickSoundPlayer`(audioplayers,
mediaPlayer 모드). 기존 테스트가 4종 카탈로그/통계 4값을 단정하므로 함께 갱신해야 함.

## Scope — what to build

### A) 스위치 카탈로그 11종 (domain + theme)
- `lib/domain/switch_type.dart`:
  - `enum SwitchKind { clicky, tactile, linear }` 추가.
  - `SwitchType`에 `final SwitchKind kind;`, `final int forceCn;`(작동압, cN) 필드 추가.
  - `SwitchCatalog.all`을 아래 **정확히 이 순서**의 11종으로 확장(기존 4종을 맨 앞에 유지):
    | id | nameKo | nameEn | kind | forceCn | stemColor(AppColors) | defaultLed(AppColors) | haptic |
    |----|--------|--------|------|---------|----------------------|-----------------------|--------|
    | blue | 청축 | Blue | clicky | 50 | switchBlue | neonCyan | 1.0 |
    | brown | 갈축 | Brown | tactile | 45 | switchBrown | neonOrange | 0.7 |
    | red | 적축 | Red | linear | 45 | switchRed | neonMagenta | 0.45 |
    | black | 흑축 | Black | linear | 60 | switchBlack | neonGreen | 0.6 |
    | white | 백축 | White | clicky | 55 | switchWhite | neonCyan | 0.85 |
    | gray | 회축 | Gray | tactile | 80 | switchGray | neonYellow | 0.95 |
    | clear | 클리어축 | Clear | tactile | 65 | switchClear | neonPurple | 0.8 |
    | silentRed | 저소음 적축 | Silent Red | linear | 45 | switchSilentRed | neonMagenta | 0.4 |
    | silentBlack | 저소음 흑축 | Silent Black | linear | 60 | switchSilentBlack | neonGreen | 0.55 |
    | speedSilver | 스피드 은축 | Speed Silver | linear | 45 | switchSpeedSilver | neonCyan | 0.5 |
    | darkGray | 진회축 | Dark Gray | linear | 80 | switchDarkGray | neonYellow | 0.9 |
  - 각 항목 description은 한 줄(예: 적축="가벼운 리니어, 구름타법"; 저소음="댐퍼로 조용함"; 스피드="1.2mm 짧은 행정"; 회축/진회축="고압"). `defaultSwitch = blue = all.first` 유지, `byId` 유지.
- `lib/theme/app_colors.dart`: 신규 스템색 추가(기존 4개 유지):
  `switchWhite #FFE5E7EB`, `switchGray #FF6B7280`, `switchClear #FFD1D5DB`,
  `switchSilentRed #FFF87171`, `switchSilentBlack #FF374151`,
  `switchSpeedSilver #FFC0C7D0`, `switchDarkGray #FF4B5563`.

### B) 사운드 (동작용, 품질 튜닝 X)
- `tools/gen_sounds.py`에 신규 7종 파라미터 추가 → 22개 WAV 생성(`<id>_down/up.wav`).
  kind로 파생: clicky≈blue 계열, tactile≈brown/clear 계열, linear≈red/black 계열,
  저소음=peak 낮추고 어둡게, speed=더 짧게, 고압(80cN)=저역 강조. 결정적 유지(고정 시드).
- 22개 WAV 커밋. (이번엔 사운드 리얼리즘 평가 안 함 — 각 축에 distinct한 합성음이 나면 됨.)

### C) UI — 통계 2개만
- `lib/widgets/stats_panel.dart`(또는 교체): **전체 클릭수**(Key `stat-total`)와 **RPM**(Key `stat-rpm`,
  값=분당 클릭수=`statsProvider`의 cpm) **딱 2개만** 크게 표시. 세션/최고/CPM 사중 타일 제거.
  리셋은 작은 아이콘 버튼 하나로 유지(확인 다이얼로그 → `resetStats()`). (statsProvider 자체는 변경 불필요.)

### D) UI — 진짜 키캡 모양 + 확실한 눌림
- `lib/widgets/keycap.dart` 재디자인:
  - **키캡 형상**: 평평한 사각이 아니라 실제 키캡처럼 — 윗면(살짝 둥근/디시드 top, 둥근 모서리)
    + 보이는 측벽(스커트)으로 입체 3D 키캡. 윗면에 레전드(선택 스위치 nameEn 또는 키 글리프).
    네온 글로우(ledColor)는 키캡 베이스 둘레.
  - **확실한 눌림**: 누르면 키캡이 **눈에 띄게 아래로 내려감**(트래블 ≥ 화면상 10px 수준) +
    살짝 축소 + 측벽이 눌리며 윗면-베이스 간격이 줄고 + 바닥 그림자 축소/소멸 + 글로우 플레어.
    떼면 스냅 복귀. "확실히 들어갔다 나온다"가 한눈에 보여야 함.
  - 기존 API 유지: `Keycap({Key?, required Color ledColor, String label, LedMode ledMode, VoidCallback? onPressDown, VoidCallback? onPressUp, double size})`.
- `lib/screens/home_screen.dart`: 키캡 label = 선택 스위치 nameEn(또는 nameKo) 반영.

### E) UI — 스위치 선택기 11종
- HomeScreen 하단 선택기를 11종 **가로 스크롤**(`ListView`/`SingleChildScrollView` horizontal)로.
  각 칩: 스템색 점/배경 + nameKo(+선택 시 forceCn/kind 작게 가능). 선택 칩 하이라이트.
  탭 → `settings.selectSwitch(id)`. 모든 칩 Key `switch-chip-<id>`.

## Out of scope
- 사운드 리얼리즘/튜닝(별도). 키 외 새 화면. 진동 로직 변경. app id/서명.

## Acceptance criteria (QA verifies each)
- [ ] AC1: `SwitchCatalog.all`이 위 11종을 정확한 순서/필드로 노출(id 유일, kind/forceCn/stemColor==AppColors.*/defaultLed∈ledPalette/haptic∈(0,1]); `defaultSwitch==all.first==blue` — 단위 테스트(갱신).
- [ ] AC2: 22개 WAV가 존재·유효(mono/44100/16-bit, >1KB)하고 `gen_sounds.py` 재실행이 결정적(바이트 동일) — 단위 테스트(갱신) + 결정성 증거.
- [ ] AC3: HomeScreen 통계 영역에 **정확히 2개** 값(`stat-total`, `stat-rpm`)만 표시되고, 탭 시 total 증가·RPM 갱신 — 위젯 테스트.
- [ ] AC4: 리셋 → 확인 다이얼로그 → 확인 시 total 0(영구) — 위젯 테스트.
- [ ] AC5: Keycap이 눌림 시 관찰가능한 "내려감" 상태로 전환(트래블/스케일이 미눌림과 명확히 다름) + onPressDown/onPressUp 각 1회 — 위젯 테스트. 골든(미눌림/눌림) 갱신.
- [ ] AC6: 선택기에 11개 칩(`switch-chip-<id>` 전부) 존재, 가로 스크롤 가능, 임의 칩(예: `switch-chip-speedSilver`) 탭 시 `settingsProvider.selectedSwitchId`가 그 값으로 바뀌고 키캡 label 갱신 — 위젯 테스트.
- [ ] AC7: `flutter analyze`="No issues found!", `dart format --set-exit-if-changed .`=0, `flutter test` 전부 green(기존 테스트 갱신 포함).
- [ ] AC8: `flutter build apk --debug` 성공. (가능하면 emulator-5554 런타임 스모크 1회: 키캡 누름→카운터, 스위치 변경; 스크린샷.)

## Test plan
- Format/Analyze: required
- Unit: required (AC1 카탈로그, AC2 자산)
- Widget: required (AC3–AC6)
- Golden: required (AC5 키캡 미눌림/눌림 갱신)
- Integration: N/A(기존 통합 흐름 유지; 깨지면 갱신)
- Build: required (AC8)
- Runtime smoke: 권장(에뮬레이터)

## Evidence
- Dev evidence:  docs/tasks/T012/evidence/dev/
- QA evidence:   docs/tasks/T012/evidence/qa/
