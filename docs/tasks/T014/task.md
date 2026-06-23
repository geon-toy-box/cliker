---
task: T014
project: cliker
milestone: M5
created: 2026-06-23
status: TODO
tags: [toybox, task]
---

# T014 — 스위치 13종 + 메뉴 정보 풍부화 (느낌·소리·추천용도)

## Context
사용자 결정: 라인업을 **13종**으로(체리 MX 11 + **황축** + **자석축**) 늘리고, 축 선택
**메뉴에 각 축의 느낌·소리세기·추천용도**를 보여 "내 취향 축 고르기"를 살린다. 기존 11종의
핵심 필드(id/nameKo/nameEn/kind/forceCn/stemColor/defaultLed/hapticStrength)는 **그대로 유지**
하고(테스트 churn 최소화), 설명 필드를 enrich + 2종 추가. 사운드 품질 튜닝은 스코프 아님(동작만).
T013(MZ 리디자인)이 이미 머지됨 — 그 메뉴(`switch_menu.dart`) 위에 정보 표시를 얹는다.

## Scope — what to build

### A) SwitchType 필드 enrich + 2종 추가
- `lib/domain/switch_type.dart`에 필드 추가:
  - `final String recommendedFor;` (추천 용도, 한 줄)
  - `final int loudness;` (1=매우 조용 … 5=매우 큼; UI 소리세기 표시용)
  - 기존 `description`은 **느낌(타건감) 한 줄**로 의미를 통일(아래 표의 "느낌").
- 신규 스템색 in `lib/theme/app_colors.dart`: `switchYellow #FFFACC15`, `switchMagnetic #FF2DD4BF`.
- `SwitchCatalog.all` = 아래 **13종**(기존 11 순서 유지 후 yellow, magnetic 추가). 기존 11종은
  id/kind/forceCn/stemColor/defaultLed/haptic **불변**, description→느낌으로 정리 + recommendedFor/loudness 추가:

  | id | nameKo | nameEn | kind | force | loud | 느낌(description) | recommendedFor |
  |----|--------|--------|------|-------|------|-------------------|----------------|
  | blue | 청축 | Blue | clicky | 50 | 5 | 또렷한 딸깍 클릭, 강한 피드백 | 타이핑·손맛·ASMR |
  | brown | 갈축 | Brown | tactile | 45 | 3 | 부드러운 구분감 범프 | 코딩·문서·입문 |
  | red | 적축 | Red | linear | 45 | 2 | 걸림 없이 부드럽게 쭉 | 게임·사무 |
  | black | 흑축 | Black | linear | 60 | 2 | 묵직·탄탄, 강한 반발 | 오타 방지·강한 입력 |
  | white | 백축 | White | clicky | 55 | 4 | 청축 손맛에 소음은 한 톤 낮게 | 손맛 + 소음↓ |
  | gray | 회축 | Gray | tactile | 80 | 3 | 고압 텍타일, 강한 구분감 | 묵직한 택타일 선호 |
  | clear | 클리어축 | Clear | tactile | 65 | 3 | 갈축보다 진한 범프 | 또렷한 구분감 |
  | silentRed | 저소음 적축 | Silent Red | linear | 45 | 1 | 댐퍼로 가장 조용한 리니어 | 사무실·공유공간 |
  | silentBlack | 저소음 흑축 | Silent Black | linear | 60 | 1 | 묵직하지만 조용하게 | 야간·정숙 환경 |
  | speedSilver | 스피드 은축 | Speed Silver | linear | 45 | 2 | 1.2mm 초고속 액추에이션 | FPS·빠른 반응 |
  | darkGray | 진회축 | Dark Gray | linear | 80 | 2 | 고압 리니어, 깊고 무겁게 | 강한 입력감 |
  | yellow | 황축 | Yellow | linear | 50 | 2 | 적축보다 쫀득·부드러운 리니어 | 커스텀 키감·부드러움 |
  | magnetic | 자석축 | Magnetic | linear | 40 | 1 | 무접점 홀이펙트·래피드 트리거 | e스포츠·정밀 제어 |

  - yellow: stem `switchYellow`, led `neonYellow`, haptic 0.5. magnetic: stem `switchMagnetic`, led `neonCyan`, haptic 0.45 (자석축은 아날로그지만 enum은 linear로; "무접점"은 description에).
  - `defaultSwitch == all.first == blue` 유지, `byId` 유지.

### B) 사운드 (동작용)
- `tools/gen_sounds.py`에 yellow, magnetic 파라미터 추가 → **26개 WAV** 생성(결정적, 고정 시드).
  yellow=적축류보다 살짝 풀바디 부드러운 리니어, magnetic=아주 매끈·조용한 리니어. 26 WAV 커밋.

### C) 스위치 메뉴 정보 표시
- `lib/widgets/switch_menu.dart` 각 행에 표시: stemColor 점/스와치 + nameKo(nameEn) +
  `kind 라벨 · forceCn cN · 소리세기(loudness를 🔊×N 또는 작은 바)` + 느낌(description) + "추천: recommendedFor".
  선택 항목 하이라이트, 각 행 Key `switch-chip-<id>` 유지. 13종이므로 시트가 스크롤되게.

## Out of scope
- 사운드 리얼리즘/튜닝. 키캡/휠/통계 등 T013 산출물 변경(메뉴 정보 표시만 추가). 새 패키지.
  app id/서명/스토어.

## Acceptance criteria (QA verifies each)
- [ ] AC1: `SwitchCatalog.all`이 위 **13종**(순서대로, yellow/magnetic 포함)을 노출, 각 항목에 recommendedFor(비어있지 않음)·loudness∈[1,5]·description(느낌); 기존 11종의 kind/forceCn/stemColor/defaultLed/haptic 불변; defaultSwitch==all.first==blue — 단위 테스트.
- [ ] AC2: switchYellow/switchMagnetic가 정확한 hex로 AppColors에 존재 — 단위 테스트.
- [ ] AC3: **26개 WAV** 존재·유효(mono/44100/16-bit >1KB), `gen_sounds.py` 재실행 결정적(바이트 동일) — 단위 테스트 + 결정성 증거.
- [ ] AC4: 축 메뉴를 열면 13개 `switch-chip-<id>`가 모두 있고, 각 행에 종류·작동압·소리세기·느낌·추천용도가 렌더됨(예: magnetic 행에 "무접점"/"e스포츠" 텍스트); 임의 신규 축(예: `switch-chip-yellow`) 선택 시 `selectedSwitchId=='yellow'`, 키캡 stemColor/label 갱신 — 위젯 테스트.
- [ ] AC5: `flutter analyze`="No issues found!", `dart format --set-exit-if-changed .`=0, `flutter test` 전부 green(영향 테스트 갱신: catalog 13, assets 26, menu). 신규 패키지 의존성 0.
- [ ] AC6: `flutter build apk --debug` 성공.

## Test plan
- Format/Analyze: required
- Unit: required (AC1 카탈로그 13, AC2 색, AC3 자산 26)
- Widget: required (AC4 메뉴 정보 표시 + 신규 축 선택)
- Golden: N/A(키캡 변경 없음; 메뉴 골든은 선택)
- Build: required (AC6)
- Runtime smoke: 권장(web/emulator — 메뉴에서 황축/자석축 보이고 선택되는지)

## Evidence
- Dev evidence:  docs/tasks/T014/evidence/dev/
- QA evidence:   docs/tasks/T014/evidence/qa/
