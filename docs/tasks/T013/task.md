---
task: T013
project: cliker
milestone: M5
created: 2026-06-23
status: TODO
tags: [toybox, task]
---

# T013 — MZ 비주얼 리디자인: 실사 스위치+키캡 / RGB 휠 / 축 메뉴

## Context
사용자(디자인 리드=플래너) 지시: ① 축 선택을 **메뉴**로 분리, ② LED 색을 **RGB 원판(휠)**으로
선택, ③ 전체 스타일을 **MZ**(홀로그래픽·글로시·버블리)하게, ④ 가운데 클릭 버튼을 **실제
기계식 스위치 + 키캡 모양**으로. 핵심 루프(탭→사운드/햅틱/통계)·11종 카탈로그·통계 2개
(전체 클릭수/RPM)·audioplayers(mediaPlayer) 유지. **사운드 품질 튜닝은 스코프 아님.**

## Design tokens (이대로 구현 — 디자인 리드 결정)
- 색: 베이스 `#FF0B0B12`, 표면 `#FF15151F`, 글래스=흰색 8~14% 오버레이.
  홀로그래픽 스윕 stops: `holoMagenta #FFFF2FB9`, `holoViolet #FF8B5CFF`, `holoCyan #FF2FE6FF`.
  텍스트 `#FFFFFFFF` / 뮤트 `#FF9A9AB2`. (기존 `AppColors`에 holo* 3색 추가, ledPalette 유지)
- 타입: 디스플레이 = system 초고중량(w900) + 좁은 자간, 큰 스케일. 숫자(클릭수)가 히어로 —
  큰 글자 + 홀로그래픽 그라데이션 필(ShaderMask). 라벨 = 작게 대문자/와이드 트래킹. 한글=시스템.
- 모서리: 크고 둥글게(버블리, radius 20~28). 그림자=소프트 글로우.
- 모션: 누름=키캡 아래로 스냅, 숫자 증가 시 살짝 팝(scale bounce), 워드마크 hue 천천히 이동.
  `MediaQuery.disableAnimations`(reduce motion) 존중.

## Scope — what to build

### A) 레이아웃 / MZ 스타일
- `lib/screens/home_screen.dart` 재구성:
  - 상단 바: 워드마크 "cliker"(홀로그래픽 그라데이션 텍스트) + 우측 **축 메뉴 버튼**(Key `switch-menu-button`, 라벨 "축"/아이콘) + 설정 기어.
  - 히어로: **전체 클릭수**를 큰 홀로그래픽 숫자로(Key `stat-total`), 그 아래 **RPM** 작은 글래스 pill(Key `stat-rpm`). (통계는 이 2개만 유지) + 작은 리셋 아이콘(확인 다이얼로그→resetStats).
  - 중앙: 실사 스위치+키캡(아래 C).
  - 하단: **RGB 휠**(아래 B) + (필요시) 설정 진입.
  - 전반: 글래스 패널, 둥근 모서리, 홀로그래픽 악센트, 소프트 글로우. 선택 LED 색이 악센트/글로우에 반영.

### B) RGB 색상 휠 (LED 선택)
- `lib/widgets/rgb_wheel.dart` — `RgbWheel`: CustomPaint **hue 링/원판**(conic 무지개) + 드래그 가능한 thumb.
  탭/드래그로 hue 선택(채도·명도는 최대 고정 또는 중앙 밝기 슬라이더는 선택). 콜백 `onColorChanged(Color)`.
  - HomeScreen에서 `settings.setLedColor(argb)`로 연결, 선택 즉시 키캡 글로우/악센트 갱신, 영구 저장.
  - 6-스와치 팔레트는 휠로 대체(설정시트의 색 스와치 제거 또는 휠로 교체).
  - Key `rgb-wheel`. 접근성: 의미 있는 제스처 영역.

### C) 실사 스위치 + 키캡 (중앙, 시그니처)
- `lib/widgets/keycap.dart` 재작업(기존 public API 유지: `ledColor/label/ledMode/onPressDown/onPressUp/size`,
  **추가** `required Color stemColor`(축 색)). 해부 구조:
  - **플레이트**: 하단 다크 라운드 베이스, 스위치 밑에서 RGB 언더글로우가 새어나옴.
  - **스위치 하우징**: 체리 MX 탑 하우징 느낌의 다크 차콜(#2A2A33) 사각 하우징(특유의 노치/스텝),
    중앙 구멍으로 **스템(+자 크로스)**이 `stemColor`로 솟음 = 축 정체성.
  - **키캡**: 스컬프처 OEM 프로파일(둥근/디시드 윗면 + 글로시 하이라이트 + 측벽)이 스템 위에 안착,
    가장자리에 RGB 림글로우. 레전드는 없거나 아주 은은하게(폼 우선).
  - **누름**: 키캡+스템이 **~20px 아래로 스냅 다운**(키캡 바닥-하우징 간격이 닫힘), 언더글로우 플레어,
    바닥 그림자 축소, 떼면 스냅 복귀. 미눌림↔눌림이 한눈에 확실히 구분.
  - `ledMode`: solid/ripple/rgbCycle(글로우 hue 순환)/reactive(누름 반응) 유지.
- CustomPaint 권장(하우징/스템/플레이트), 키캡은 레이어드 그라데이션 가능. innerCapKey로 눌림 상태 테스트 가능하게 유지.

### D) 축 선택 메뉴
- `lib/widgets/switch_menu.dart`(또는 sheet) — 축 메뉴 버튼 → 글래스 모달 바텀시트.
  11종 리스트(각: stemColor 점/프리뷰 + nameKo + kind·forceCn). 탭 → `settings.selectSwitch(id)` 후 닫힘.
  선택 항목 하이라이트. **각 항목 Key `switch-chip-<id>` 유지**(기존 선택 테스트 호환). 키캡 stemColor/label 갱신.
- HomeScreen 하단의 기존 가로 칩 행은 제거(메뉴로 이동).

## Out of scope
- 사운드 품질/합성 변경(동작 유지). 새 패키지(컬러피커 등) 추가 금지 — 휠은 CustomPaint 자체 구현.
  앱 식별/서명/스토어. 라이트 테마.

## Acceptance criteria (QA verifies each)
- [ ] AC1: 축 칩이 더 이상 메인에 상시 노출되지 않고, `switch-menu-button` 탭 시 11종 메뉴가 열린다(11개 `switch-chip-<id>` 존재) — 위젯 테스트.
- [ ] AC2: 메뉴에서 임의 축(예: `switch-chip-speedSilver`) 탭 → `settingsProvider.selectedSwitchId`가 그 값, 메뉴 닫힘, 키캡 stemColor/label 갱신 — 위젯 테스트.
- [ ] AC3: `RgbWheel`에서 위치를 선택하면 `onColorChanged`가 색을 내보내고 `settingsProvider.ledColorArgb`가 갱신·영구(새 컨테이너 유지), 키캡 글로우 색이 따라감 — 위젯/단위 테스트.
- [ ] AC4: 통계는 여전히 정확히 2개(`stat-total`,`stat-rpm`)만, 탭 시 증가; 리셋 확인→0(영구) — 위젯 테스트.
- [ ] AC5: 키캡 누름 시 관찰가능한 눌림 상태(트래블/스케일이 미눌림과 명확히 다름) + `onPressDown/onPressUp` 각 1회; `stemColor`가 렌더에 반영 — 위젯 테스트. 골든(미눌림/눌림) 갱신.
- [ ] AC6: `flutter analyze`="No issues found!", `dart format --set-exit-if-changed .`=0, `flutter test` 전부 green(영향받은 테스트 갱신). 신규 패키지 의존성 0.
- [ ] AC7: `flutter build apk --debug` 성공. (가능하면 web 또는 emulator 런타임 스모크 스크린샷.)

## Test plan
- Format/Analyze: required
- Unit: RGB 휠 색 매핑(좌표→hue→Color) 단위 테스트 권장
- Widget: required (AC1–AC5)
- Golden: required (AC5 키캡 갱신; RGB 휠 1컷 골든 선택)
- Build: required (AC7)
- Runtime smoke: 권장(web/emulator)

## Evidence
- Dev evidence:  docs/tasks/T013/evidence/dev/
- QA evidence:   docs/tasks/T013/evidence/qa/
