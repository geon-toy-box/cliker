# Dev report — T007

Status: implemented and self-checked; awaiting QA.

## Summary
Added the settings UI (a modal `SettingsSheet` opened from a gear button on
`HomeScreen`) bound to the existing `settingsProvider`, and implemented the
visual behavior of the LED effect modes in `Keycap` (`solid`, `ripple`,
`rgbCycle`, `reactive`) behind a new backward-compatible `ledMode` prop. No new
package dependencies; the M1 core loop and all existing tests still pass.

## Changes
- `lib/widgets/keycap.dart:33,45` — new `LedMode ledMode` prop (default
  `LedMode.ripple`), keeping the existing `ledColor`/`label`/`onPressDown`/
  `onPressUp`/`size` API intact.
- `lib/widgets/keycap.dart:74,78` — `rgbCycleDuration` (6s) and
  `reactiveDecayDuration` (1200ms) constants, exposed so tests pump known time.
- `lib/widgets/keycap.dart:99-108` — `_cycle` (looping) and `_reactive`
  AnimationControllers; switched the State mixin to `TickerProviderStateMixin`.
- `lib/widgets/keycap.dart:120-145` — `_applyMode()` (start/stop the per-mode
  controllers on mount and on `didUpdateWidget`); `rgbCycle` calls
  `_cycle.repeat()`.
- `lib/widgets/keycap.dart:158-161` — on press-down in `reactive`, the
  `_reactive` flare snaps to 1.0 and decays.
- `lib/widgets/keycap.dart:204-216` — `_effectiveLedColor()` hue-rotates the
  base color for `rgbCycle` (HSV), else returns `ledColor`; ripples use it.
- `lib/widgets/keycap.dart:226-231` — `_glowIntensity()` returns the decaying
  reactive flare in `reactive`, else the press-depth glow.
- `lib/widgets/keycap.dart:247,287-288` — glow built from
  `_effectiveLedColor()`/`_glowIntensity()`; the merged `_press`/`_cycle`/
  `_reactive` Listenable drives the rebuild. Ripples now live inside the press
  `Transform.scale` (golden output unchanged — see test-golden.txt).
- `lib/widgets/settings_sheet.dart` — new file: `SettingsSheet` (ConsumerWidget)
  with sound toggle (`setSound`, :85,88), haptic toggle (`setHaptic`, :94), six
  `AppColors.ledPalette` swatches with a ringed selection (`setLedColor`, :103),
  and four LED-mode `ChoiceChip`s (`setLedMode`, :112). `show()` (:41) opens it
  as a modal bottom sheet. Test keys at :25,28,31,34,37.
- `lib/screens/home_screen.dart:9` — import `SettingsSheet`.
- `lib/screens/home_screen.dart:33,73-83` — settings `IconButton`
  (`settingsButtonKey`) right-aligned above the stats; `onPressed` →
  `SettingsSheet.show(context)`.
- `lib/screens/home_screen.dart:88` — pass `ledMode: settings.ledMode` to the
  `Keycap`.

(`git diff --stat` covers only the two tracked, modified files; the three new
files below are untracked — see Self-audit for the full reconciliation.)

## Tests added
- `test/widget/led_modes_test.dart` — 4 widget tests (AC4 + back-compat):
  `rgbCycle` glow hue changes as time is pumped; `solid` keeps a steady hue over
  the same span; `reactive` glow intensity (shadow alpha) rises right after a
  press then decays; default (`ripple`) keycap glows steadily in its base color.
- `test/widget/settings_sheet_test.dart` — 5 widget tests (AC1–AC3 +
  persistence): the gear opens the sheet showing both toggles, all six swatches,
  all four mode chips (AC1); sound OFF → `soundEnabled==false` and a keycap press
  plays no sound while haptic still fires (AC2); haptic OFF → `hapticEnabled==
  false` and no vibration while sound still plays (AC2); selecting neonMagenta
  sets `ledColorArgb`, recolors the keycap glow, and survives a fresh container
  (AC3); selecting rgbCycle sets `ledMode` and survives a fresh container.
  Reuses the M1 fake `SoundBackend` + the platform-channel haptic spy.

## Verification evidence
- Format:    evidence/dev/format.txt — `Formatted 30 files (0 changed)`, EXIT_CODE=0
- Analyze:   evidence/dev/analyze.txt — `No issues found!`, EXIT_CODE=0
- Unit:      evidence/dev/test-unit.txt — `+79 ... All tests passed!`, EXIT_CODE=0
- Widget:    evidence/dev/test-widget.txt — `+30 ... All tests passed!`, EXIT_CODE=0
  (includes new led_modes 4 + settings_sheet 5; per-file confirmed 4 and 5)
- Golden:    evidence/dev/test-golden.txt — `+2 ... All tests passed!`, EXIT_CODE=0
  (resting + pressed goldens unchanged → Keycap restructure is visually safe)
- Full suite: evidence/dev/test-all.txt — `+109 ... All tests passed!`, EXIT_CODE=0
- Build:     evidence/dev/build.txt — `✓ Built build/app/outputs/flutter-apk/app-debug.apk`,
  EXIT_CODE=0; artifact `app-debug.apk` 189299825 bytes (`ls -l`).
- Integration: N/A per task.md (single-screen interaction; end-to-end is T006).
- Runtime smoke: evidence/dev/smoke/ on `emulator-5554` (API 35), package
  `com.geontoybox.cliker`:
  - 01-home.png — cold launch, gear visible top-right, cyan keycap glow.
  - 02-settings-open.png — sheet open: 설정 title, sound/haptic toggles ON, six
    swatches (cyan ringed), four mode chips (리플 selected).
  - 03-settings-changed.png — after changing in-sheet: sound OFF, magenta swatch
    ringed, RGB 순환 chip selected. All three reflected immediately.
  - 04-home-rgbcycle.png / 05-home-rgbcycle-later.png — dismissed sheet; the
    rgbCycle glow is mid-cycle and visibly shifts hue (greenish → orange) ~1.5s
    apart, proving the cycle animates at runtime.
  - logcat.txt — fatal/crash scan found none (`E/flutter`, `FATAL`,
    `AndroidRuntime` all absent); process still alive (pidof returned a pid).

## Self-audit
Confirmed every claim above is backed by a file under `evidence/dev/` with a
matching EXIT_CODE/result, and that I read each command's full output and exit
code this session.

`git diff --stat` (tracked files only):
```
 lib/screens/home_screen.dart |  17 ++++
 lib/widgets/keycap.dart      | 181 +++++++++++++++++++++++++++++++++++--------
 2 files changed, 165 insertions(+), 33 deletions(-)
```
Untracked new files (`git status --porcelain | grep '^??'`, source/test only):
```
?? lib/widgets/settings_sheet.dart
?? test/widget/led_modes_test.dart
?? test/widget/settings_sheet_test.dart
```
Reconciliation: the Changes list = the 2 tracked modified files + the 3
untracked new files, with no other source/test files touched. (The repo also
contains the generated `docs/tasks/T007/evidence/**` and this `dev.md`, which
are reports/evidence, not code changes.)

## Known limitations / UNVERIFIED
- `rgbCycle` runtime hue-shift (smoke frames 04→05) is verified by eye from two
  screenshots; the deterministic hue-advance assertion lives in the widget test
  (led_modes_test.dart), which is the authoritative check.
- The bottom sheet is dismissed in tests by tapping the scrim at a fixed corner
  offset; this is intentional (an active rgbCycle keypad animation makes
  `pumpAndSettle` time out, documented inline in the rgbCycle persistence test).
- Golden coverage for the new modes was deliberately skipped per task.md
  (rgbCycle/reactive are time-dependent and would be flaky); the existing solid
  goldens still pass unchanged.
- Smoke `누적`(total) shows 30 from prior emulator runs — persisted state, not a
  regression.
