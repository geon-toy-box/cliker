# Dev report — T001

## Summary
Built the dark + neon-RGB design system: color tokens (`AppColors`), spacing/radius
scales (`AppSpacing`/`AppRadius`), and a dark `ThemeData` (`appTheme()`) with an
explicitly-constructed `ColorScheme.dark` so `colorScheme.primary` is exactly
`AppColors.neonCyan`. No new package dependencies; no widget/screen/main.dart changes.

## Changes
All changes are new (untracked) files — nothing pre-existing was modified.
`git status --short` shows exactly:
```
?? lib/theme/
?? test/unit/app_colors_test.dart
?? test/unit/app_spacing_test.dart
?? test/unit/app_theme_test.dart
```
Files:
- `lib/theme/app_colors.dart:1` — `abstract final class AppColors`; all bg/surface,
  keycap, text, neon-LED, and switch-stem tokens as `static const Color`,
  `accentDefault = neonCyan`, and `static const List<Color> ledPalette` (6 neon colors).
- `lib/theme/app_spacing.dart:2` — `AppSpacing` (xs/sm/md/lg/xl/xxl = 4/8/16/24/32/48);
  `:14` `AppRadius` (sm/md/lg/pill = 8/14/20/999).
- `lib/theme/app_theme.dart:11` — `ThemeData appTheme()`: `Brightness.dark`,
  `scaffoldBackgroundColor: AppColors.bg`, explicit `ColorScheme.dark` (NOT fromSeed)
  with `primary: AppColors.neonCyan`, `surface: AppColors.surface`,
  `onSurface: AppColors.textPrimary`; readable text theme + `AppRadius.md` rounded corners.
- `test/unit/app_colors_test.dart:1` — AC1 (every token's `toARGB32()`), AC4 (palette).
- `test/unit/app_spacing_test.dart:1` — AC3 (spacing + radius values).
- `test/unit/app_theme_test.dart:1` — AC2 (theme brightness / scaffold bg / primary / surface).

## Tests added
- `test/unit/app_colors_test.dart` — AC1: each of the 21 color tokens asserted via
  `color.toARGB32() == 0xFF......`; AC4: `ledPalette` has length 6 and equals the
  6 neon colors in canonical order (also verified by ARGB list).
- `test/unit/app_spacing_test.dart` — AC3: all 6 `AppSpacing` + 4 `AppRadius` values.
- `test/unit/app_theme_test.dart` — AC2: `brightness == dark`,
  `scaffoldBackgroundColor == AppColors.bg`, `colorScheme.primary == neonCyan`,
  plus surface/onSurface/colorScheme.brightness.

## Verification evidence
- Format:   evidence/dev/format.txt — `Formatted 8 files (0 changed)` — EXIT_CODE=0
- Analyze:  evidence/dev/analyze.txt — `No issues found! (ran in 1.3s)` — EXIT_CODE=0
- Unit:     evidence/dev/test-unit.txt — `+15 All tests passed!` — EXIT_CODE=0
- Full suite: evidence/dev/test-all.txt — `+16 All tests passed!` (15 unit + 1 pre-existing
  smoke widget; confirms main.dart untouched) — EXIT_CODE=0
- Widget:  N/A — task adds no widgets/screens (spec Test plan).
- Golden / Integration / Build / Runtime smoke: N/A — no rendered surface, flow, or
  app-entrypoint change in this task (spec Test plan marks each N/A).

## AC → evidence map
- AC1 (token ARGB values): evidence/dev/test-unit.txt (app_colors_test.dart, EXIT_CODE=0)
- AC2 (theme): evidence/dev/test-unit.txt (app_theme_test.dart, EXIT_CODE=0)
- AC3 (spacing/radius): evidence/dev/test-unit.txt (app_spacing_test.dart, EXIT_CODE=0)
- AC4 (ledPalette order/contents): evidence/dev/test-unit.txt (app_colors_test.dart, EXIT_CODE=0)
- AC5 (analyze + format): evidence/dev/analyze.txt + evidence/dev/format.txt (both EXIT_CODE=0)

## Self-audit
Confirmed: every claim above is backed by a file in evidence/dev/ with a matching
EXIT_CODE line. The Changes list matches the working tree — `git status --short`
shows only the 3 untracked test files plus the untracked `lib/theme/` directory
(3 source files); `git diff --stat` is empty because all files are new/untracked.
No tracked file (including `lib/main.dart` and the existing smoke widget test) was modified.

## Known limitations / UNVERIFIED
- Theme cosmetics beyond the AC-checked properties (text theme tones, card/appbar/button
  shaping) are implemented but only the AC2 properties are asserted by tests; the rest are
  UNVERIFIED by automated test (no rendered surface exists yet to golden-test them — that
  arrives with T005).
- Implemented and self-checked; awaiting QA.
