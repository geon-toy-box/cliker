---
task: T001
project: cliker
milestone: M1
created: 2026-06-22
status: TODO
tags: [toybox, task]
---

# T001 — Foundation: dark RGB theme tokens

## Context
모든 화면이 이 위에 그려진다. cliker의 비주얼 무드는 **다크 + 네온 RGB 게이밍**
(키보드 LED 감성)이다. 이 작업은 그 무드를 Flutter 테마 토큰(색/간격/모서리)과
`ThemeData`로 고정해, 이후 키캡·LED·통계 위젯이 일관된 톤으로 빠르게 만들어지게 한다.
신규 패키지 의존성은 추가하지 않는다(pubspec 충돌 방지 — 다른 작업과 병렬 안전).

## Scope — what to build
- `lib/theme/app_colors.dart` — `AppColors` 클래스에 named `static const Color` 토큰 (정확한 hex):
  - 배경/표면: `bg #FF0A0A0F`, `surface #FF15151F`, `surfaceHi #FF1F1F2E`
  - 키캡: `keycapBase #FF1E1E28`, `keycapTop #FF2A2A3A`, `keycapEdge #FF101018`
  - 텍스트: `textPrimary #FFFFFFFF`, `textMuted #FF8A8A99`
  - 네온 LED 팔레트(`List<Color> ledPalette`로도 노출): `neonCyan #FF00E5FF`,
    `neonMagenta #FFFF2D95`, `neonGreen #FF39FF14`, `neonPurple #FFB026FF`,
    `neonOrange #FFFF6B1A`, `neonYellow #FFFFE600`
  - 스위치 스템 색: `switchBlue #FF3B82F6`, `switchBrown #FF92400E`, `switchRed #FFEF4444`, `switchBlack #FF111827`
  - `accentDefault` = `neonCyan` (기본 LED 색)
- `lib/theme/app_spacing.dart` — `AppSpacing`(static const double): `xs 4, sm 8, md 16, lg 24, xl 32, xxl 48`.
  `AppRadius`: `sm 8, md 14, lg 20, pill 999`.
- `lib/theme/app_theme.dart` — `ThemeData appTheme()` (dark):
  - `brightness: Brightness.dark`, `scaffoldBackgroundColor: AppColors.bg`
  - `ColorScheme.dark`를 명시 구성: `primary: AppColors.neonCyan`, `surface: AppColors.surface`,
    `onSurface: AppColors.textPrimary` (seed 사용 금지 — primary가 정확히 neonCyan이어야 AC 검증 가능)
  - 가독성 있는 텍스트 테마(textPrimary/textMuted 기반), 둥근 모서리 기본값(`AppRadius.md`).

## Out of scope
- 키캡/LED/통계/스크린/위젯 일체 (T005, T006 등).
- main.dart/app.dart 와이어링 (T006). 신규 패키지 의존성 추가 금지.

## Acceptance criteria (QA verifies each)
- [ ] AC1: `AppColors`가 위 모든 토큰을 노출하고 각 색의 32-bit ARGB 값이 정확히 명시 hex와 일치 — 단위 테스트가 `color.toARGB32() == 0xFF......`로 검증(전 토큰).
- [ ] AC2: `appTheme()`가 반환한 `ThemeData`의 `brightness == Brightness.dark`, `scaffoldBackgroundColor == AppColors.bg`, `colorScheme.primary == AppColors.neonCyan` — 단위 테스트로 검증.
- [ ] AC3: `AppSpacing`/`AppRadius` 상수가 위 정확한 값으로 존재 — 단위 테스트로 검증.
- [ ] AC4: `AppColors.ledPalette`가 정확히 6개 네온 색을 위 순서대로 담는다 — 단위 테스트로 검증.
- [ ] AC5: `flutter analyze` → "No issues found!", `dart format --set-exit-if-changed .` → 0.

## Test plan — which pyramid layers apply
- Format / Analyze: required
- Unit: required (AC1 토큰 값, AC2 테마, AC3 간격/모서리, AC4 팔레트)
- Widget: N/A: 이 작업엔 위젯/스크린이 없음 (테마만)
- Golden: N/A: 렌더되는 위젯 표면이 아직 없음 (키캡 골든은 T005)
- Integration: N/A: 플로우/스크린 없음
- Build: N/A: 앱 엔트리포인트 변경 없음 (테마는 단위 테스트로 검증)
- Runtime smoke: N/A: 실행 가능한 새 화면 없음

## Evidence
- Dev evidence:  docs/tasks/T001/evidence/dev/
- QA evidence:   docs/tasks/T001/evidence/qa/
