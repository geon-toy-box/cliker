# Dev report — T013

Status: implemented and self-checked; awaiting QA.

## Summary
Rebuilt the cliker home experience in the MZ (holographic / glossy / bubbly)
language: a holographic wordmark + hero click-count, a self-built `RgbWheel` LED
picker (no new packages), a realistic mechanical switch + keycap (plate + Cherry-
MX housing + colored stem + sculpted glossy cap with RGB underglow), and a glass
switch-selection bottom sheet replacing the old inline chip row. The core
tap→sound/haptic/stats loop, the 11-switch catalog, the 2-stat model, and the
audioplayers mediaPlayer mode are all untouched.

## Changes
(matches `git diff --stat`, pasted under Self-audit)

- `lib/theme/app_colors.dart:25-27,66-70` — added `holoMagenta #FFFF2FB9`,
  `holoViolet #FF8B5CFF`, `holoCyan #FF2FE6FF` and a `holoSweep` list; `ledPalette`
  kept intact.
- `lib/widgets/rgb_wheel.dart` (new) — `RgbWheel` (Key `rgb-wheel`,
  `rgb_wheel.dart:48`): `CustomPaint` conic hue ring + draggable thumb, tap/drag →
  `onColorChanged(Color)` (`:35,:88-89`). Static, pure `hueAt`/`colorForHue`
  (`:55,:76`) make the coordinate→hue→Color mapping unit-testable. No third-party
  package.
- `lib/widgets/keycap.dart` — redesigned to a switch+keycap stack. Added the new
  `required Color stemColor` (`:47`); kept the existing public API
  (ledColor/label/ledMode/onPressDown/onPressUp/size) and all timing constants.
  New `KeycapSwitchPainter` (`:338`) paints plate + LED underglow + Cherry-MX
  charcoal housing (`#2A2A33`) with stepped notches + the `+`-cross stem in
  `stemColor`. The sculpted glossy cap travels `pressTravelFraction = 0.075`
  (~18px @ default size, `:89,:300`). Kept `innerCapKey` (`:110,:382`) with the
  LED glow as its first `BoxShadow` (test contract). Added `switchLayerKey`
  (`:114,:337`) so tests can read `stemColor` off the painter.
- `lib/widgets/switch_menu.dart` (new) — `SwitchMenu` glass bottom sheet (root Key
  `switch-menu-sheet`, `:22`). All 11 switches as rows, each Key `switch-chip-<id>`
  (`:25,:169`); tap → `selectSwitch(id)` + `Navigator.pop` (`:134-135`). Built as a
  `SingleChildScrollView`+`Column` so all 11 are always in the tree.
- `lib/widgets/stats_panel.dart` — redesigned into the MZ hero: giant holographic
  total (`stat-total`) via `ShaderMask` over `holoSweep` with a per-increment pop
  (`_HeroNumber`, `:69,:125`), RPM glass pill (`stat-rpm`, `:31`), small reset →
  confirm dialog → `resetStats` (`:117`). Reduce-motion respected (`:47-48`). All
  stat/reset keys preserved.
- `lib/screens/home_screen.dart` — MZ layout: holographic `cliker` wordmark, top-
  right `switch-menu-button` (Key `:43,:131`) opening `SwitchMenu` (`:136`) +
  settings gear, `StatsPanel` hero (`:86`), the new `Keycap` fed
  `stemColor: selected.stemColor` + `ledColor: Color(settings.ledColorArgb)`
  (`:90-91`), and a bottom `_LedWheelPanel` with the `RgbWheel` wired to
  `setLedColor` (`:102-106`). Old inline horizontal chip row removed. The keycap
  label is now the Korean name (`nameKo`). `HomeScreen.switchChipKey` now delegates
  to `SwitchMenu.switchChipKey` (`:40`) so existing key lookups still resolve.
- `lib/widgets/settings_sheet.dart` — replaced the six color swatches (and the
  `_ColorSwatches`/`_Swatch` widgets + `swatchKey`) with an embedded `RgbWheel`
  bound to `setLedColor` (`:98-103`). Toggles + mode chips unchanged.

Tests touched:
- `test/unit/app_colors_test.dart` — assert the three holo tokens + `holoSweep`.
- `test/unit/rgb_wheel_test.dart` (new) — `hueAt` / `colorForHue` mapping.
- `test/widget/rgb_wheel_test.dart` (new) — render + tap-emits-new-hue + drag.
- `test/widget/keycap_test.dart` — added `stemColor` to every Keycap; added an
  AC5 test reading `stemColor` off `KeycapSwitchPainter`.
- `test/widget/led_modes_test.dart` — added `stemColor` to every Keycap.
- `test/widget/keycap_golden_test.dart` — added `stemColor`; goldens regenerated.
- `test/widget/settings_sheet_test.dart` — AC1 asserts the in-sheet `RgbWheel`
  (not swatches); AC3 picks a hue on the home wheel and checks provider + glow +
  persistence.
- `test/widget/smoke_widget_test.dart` — cold-start asserts chips are behind the
  menu (not inline) and appear after tapping `switch-menu-button`; switch-selection
  tests open the menu first; keycap label assertions use `nameKo`.
- `test/widget/goldens/keycap_*.png` — deliberately regenerated for the new cap.

## Tests added / updated
- `test/unit/rgb_wheel_test.dart` — coordinate→hue (top=0°, right=90°, etc.) and
  hue→vivid-HSV-color mapping, wrap-around.
- `test/widget/rgb_wheel_test.dart` — wheel renders by key; tapping the right edge
  emits ~90° (a new color); dragging emits multiple distinct hues.
- `test/widget/keycap_test.dart::AC5` — `stemColor` reaches `KeycapSwitchPainter`
  and a different switch repaints with a different stem color.
- `test/unit/app_colors_test.dart` — holo tokens + `holoSweep` ARGB.

## Verification evidence
- Format:    `evidence/dev/format.txt` — `0 changed`, EXIT_CODE=0
- Analyze:   `evidence/dev/analyze.txt` — "No issues found!", EXIT_CODE=0
- Unit:      `evidence/dev/test-unit.txt` — +143 passed, EXIT_CODE=0
- Widget:    `evidence/dev/test-widget.txt` — +42 passed (incl. goldens), EXIT_CODE=0
- Golden:    `evidence/dev/test-golden.txt` — +2 passed on a clean run (regenerated
  deliberately, then re-run without `--update-goldens`), EXIT_CODE=0
- Full suite:`evidence/dev/test-all.txt` — +186 passed, EXIT_CODE=0
- Build:     `evidence/dev/build.txt` — `app-debug.apk` at
  `build/app/outputs/flutter-apk/app-debug.apk`, 154,383,712 bytes, EXIT_CODE=0
- Smoke:     `evidence/dev/smoke/screenshot-1.png` + `evidence/dev/smoke/logcat.txt`
  — installed + launched `com.geontoybox.cliker/.MainActivity` on emulator-5554
  (am start -W → Status: ok); screenshot shows the live MZ UI (holo wordmark, holo
  hero "0", RPM pill, switch+keycap "청축", RGB wheel); `FATAL EXCEPTION` count = 0.

## Acceptance criteria → evidence
- AC1 (chips not inline; `switch-menu-button` opens 11 chips): smoke_widget_test
  "cold start …" + the menu open; `home_screen.dart:43,131,136`, `switch_menu.dart`.
  Evidence: `evidence/dev/test-widget.txt`.
- AC2 (menu tap selects switch, closes, keycap updates): smoke_widget_test
  "opening the menu and tapping 적축 …"; `switch_menu.dart:134-135`,
  `home_screen.dart:91`. Evidence: `evidence/dev/test-widget.txt`.
- AC3 (RgbWheel pick → `onColorChanged`, provider updated + persisted, keycap glow
  follows): rgb_wheel_test (unit+widget) + settings_sheet_test AC3;
  `rgb_wheel.dart:88-89`, `home_screen.dart:102-106`. Evidence:
  `evidence/dev/test-unit.txt`, `evidence/dev/test-widget.txt`.
- AC4 (exactly 2 stats, increment, reset→0 persisted): stats_panel_test +
  smoke_widget_test; `stats_panel.dart:28,31,117`. Evidence:
  `evidence/dev/test-widget.txt`.
- AC5 (observable pressed state; one onPressDown/onPressUp; stemColor in render;
  goldens): keycap_test AC2 (`_pressScale` rest≈1.0 → <1.0) + AC5
  (`KeycapSwitchPainter.stemColor`) + regenerated goldens; `keycap.dart:89,300,
  337-338,382`. Evidence: `evidence/dev/test-widget.txt`, `evidence/dev/test-golden.txt`,
  `test/widget/goldens/keycap_*.png`.
- AC6 (analyze clean, format 0, all tests green, 0 new deps): `evidence/dev/
  analyze.txt`, `format.txt`, `test-all.txt`; pubspec.yaml unchanged (no new deps).
- AC7 (debug APK builds; runtime smoke): `evidence/dev/build.txt` +
  `evidence/dev/smoke/`.

## Self-audit
Confirmed: every claim above is backed by a file under `evidence/dev/` with a
matching EXIT_CODE / result, and the Changes list equals `git diff --stat`. No new
package dependency (pubspec.yaml not in the diff). I did not run `git commit`. I did
not self-certify VERIFIED/DONE — QA owns those.

`git diff --stat` (lib + test + pubspec, including the 4 new files):
```
 lib/screens/home_screen.dart             | 296 +++++++++++++--------
 lib/theme/app_colors.dart                |  14 +
 lib/widgets/keycap.dart                  | 426 +++++++++++++++++++++++--------
 lib/widgets/rgb_wheel.dart               | 208 +++++++++++++++
 lib/widgets/settings_sheet.dart          |  92 +------
 lib/widgets/stats_panel.dart             | 255 ++++++++++++------
 lib/widgets/switch_menu.dart             | 237 +++++++++++++++++
 test/unit/app_colors_test.dart           |  22 ++
 test/unit/rgb_wheel_test.dart            |  89 +++++++
 test/widget/goldens/keycap_pressed.png   | Bin 25528 -> 37237 bytes
 test/widget/goldens/keycap_unpressed.png | Bin 23955 -> 28652 bytes
 test/widget/keycap_golden_test.dart      |  16 +-
 test/widget/keycap_test.dart             |  53 +++-
 test/widget/led_modes_test.dart          |  11 +-
 test/widget/rgb_wheel_test.dart          |  91 +++++++
 test/widget/settings_sheet_test.dart     |  59 +++--
 test/widget/smoke_widget_test.dart       |  96 ++++---
 17 files changed, 1524 insertions(+), 441 deletions(-)
```

## Known limitations / UNVERIFIED
- The seated keycap covers the cross stem in the resting/pressed goldens (as on a
  real board, the cap sits on the stem), so the `stemColor` is not visually
  prominent in those two captures. The stem color IS verified to reach the render
  (keycap_test AC5) and is shown prominently as the per-switch dots in the switch
  menu. This is a faithful-to-hardware choice, not a missing feature.
- Two cliker packages exist on the emulator (`com.geontoybox.cliker` = this build's
  applicationId, and a stale `com.secondsyndrome.cliker`). The smoke evidence is
  from the correct `com.geontoybox.cliker`; the stale package is unrelated to this
  task and was left untouched.
- The hero number runs a per-increment "pop" `AnimationController`; tests that tap
  the keycap use `pump`, not `pumpAndSettle`, to avoid blocking on it (as the
  pre-existing rgbCycle tests already do). UNVERIFIED: no dedicated test asserts the
  pop scale value itself (it is reduce-motion gated and cosmetic).
- ASSUMPTION: the design spec's "메뉴" for switches is best served by a modal bottom
  sheet (matching the existing settings sheet pattern); the `switch-menu-sheet` root
  key is new (additive), while the per-row `switch-chip-<id>` keys are preserved.
