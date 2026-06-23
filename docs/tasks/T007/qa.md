# QA verdict — T007

## Verdict: PASS

All evidence below was generated independently this session under
`docs/tasks/T007/evidence/qa/` (a separate subtree from the developer's). No
source was modified for the final state — the AC4 mutation probe patched and
then restored `keycap.dart` to its original sha
`d8013102cd7de458fe1eaae69c391e25dfe4ca54`.

## Independent test results
- Format:      evidence/qa/format.txt — `Formatted 30 files (0 changed)`, EXIT_CODE=0
- Analyze:     evidence/qa/analyze.txt — `No issues found! (ran in 1.6s)`, EXIT_CODE=0
- Unit:        evidence/qa/test-unit.txt — `+79 ... All tests passed!`, EXIT_CODE=0
- Widget:      evidence/qa/test-widget.txt — `+30 ... All tests passed!`, EXIT_CODE=0
  (includes led_modes 4 + settings_sheet 5 new tests)
- Golden:      evidence/qa/test-golden.txt — `+2 ... All tests passed!`, EXIT_CODE=0
  (run WITHOUT `--update-goldens`; existing goldens still match the restructured Keycap)
- Full suite:  evidence/qa/test-all.txt — `+109 ... All tests passed!`, EXIT_CODE=0
- Coverage:    evidence/qa/coverage.txt — 93.6% overall (497/531); the three T007
  files at 100%: keycap.dart 126/126, home_screen.dart 93/93, settings_sheet.dart 84/84.
  (task.md sets no numeric threshold; recorded for completeness.)
- Mutation probe: evidence/qa/mutation-probe.txt — neutralizing hue rotation +
  reactive intensity made the rgbCycle-change and reactive-rise tests FAIL
  (+2 -2). AC4 tests are genuine, not vacuous.
- Integration: N/A per task.md line 49 (single-screen interaction; end-to-end is T006).
- Build:       evidence/qa/build.txt — `✓ Built build/app/outputs/flutter-apk/app-debug.apk`,
  EXIT_CODE=0; artifact on disk: `app-debug.apk` 189299825 bytes (181 MB).
- Smoke:       evidence/qa/smoke/ on emulator-5554 (API 35), pkg com.geontoybox.cliker.
  logcat scan: NO FATAL/AndroidRuntime/E flutter/crash lines; process pid 7191 alive.

## Document audit
evidence/qa/doc-audit.txt — every dev.md claim BACKED. Zero UNBACKED, zero
CONTRADICTED. All code line-citations verified against the tree at the exact
cited lines; all result claims re-run and matched (counts, exit codes, artifact
size byte-for-byte); `git diff --stat` and an empty `pubspec` diff confirm no
undocumented source/test changes and no new package deps. Audit PASSES.

## Spec conformance (AC1–AC6)
- AC1 (settings entry + sheet contents) → MET.
  Source: home_screen.dart:75-81 gear IconButton -> SettingsSheet.show;
  settings_sheet.dart renders sound/haptic toggles, six AppColors.ledPalette
  swatches, four LedMode chips. Test: settings_sheet_test.dart AC1 asserts the
  sheet root, both toggle keys, all 6 swatch keys, all 4 mode chip keys
  (evidence/qa/test-widget.txt +30). Runtime: evidence/qa/smoke/02-settings-open.png
  shows 설정 + 사운드/햅틱 toggles + 6 swatches + 리플/솔리드/RGB 순환/반응형.
- AC2 (toggles suppress at the source, via Fake/spy) → MET.
  Test: settings_sheet_test.dart asserts sound OFF -> soundEnabled==false AND
  `backend.played` isEmpty while `vibrateArgs` hasLength(1); haptic OFF ->
  hapticEnabled==false AND `vibrateArgs` isEmpty while `backend.played`
  hasLength(2). These are real spy assertions on the M1 FakeBackend +
  platform-channel haptic handler, not no-ops. evidence/qa/test-widget.txt.
- AC3 (swatch -> provider + glow + persists) → MET.
  Test: selecting neonMagenta sets ledColorArgb==magenta, recolors
  keycapGlowColor() (low-24-bits match), and a fresh ProviderContainer over the
  same prefs still reads magenta. evidence/qa/test-widget.txt. Runtime:
  03-settings-changed.png (cyan swatch ringed) -> 04-home-reactive.png keycap
  glow turns cyan, confirming swatch->glow propagation live.
- AC4 (mode persists; rgbCycle hue changes over time; reactive brightens on
  press) → MET. Source: keycap.dart:204-215 hue-rotates only for rgbCycle;
  :226-232 reactive decay branch; :158-163 press flare. Tests:
  led_modes_test.dart asserts rgbCycle glow color differs across pumped quarters
  (color_t1 != color_t2), solid stays constant over the same span (back-compat),
  reactive justPressed > resting then decayed < justPressed. FALSIFICATION:
  evidence/qa/mutation-probe.txt — with hue/intensity zeroed those tests FAIL
  (+2 -2), so they truly observe change. Persistence covered by settings_sheet
  rgbCycle fresh-container test.
- AC5 (analyze clean, format exit 0, tests green) → MET.
  evidence/qa/analyze.txt, format.txt, test-all.txt — all above.
- AC6 (flutter build apk --debug succeeds) → MET.
  evidence/qa/build.txt EXIT_CODE=0 + artifact 189299825 bytes on disk.

## Regression check (M1 core loop — required by lead)
- Keycap public API intact (ledColor/label/onPressDown/onPressUp/size); ledMode
  added as a backward-compatible optional prop defaulting to LedMode.ripple
  (keycap.dart:30-38). Existing keycap_test.dart + keycap_golden_test.dart pass
  unchanged (in the +30 widget / +2 golden runs).
- Tap -> sound/haptic/stats wiring unbroken: runtime smoke tapped the keycap 5x;
  누적 30->35, 세션 0->5, CPM 0->5 (evidence/qa/smoke/04-home-reactive.png ->
  05-home-after-taps.png). Counter increments; core loop works after settings
  changes.

## Dev caveats — confirmed legitimate
- rgbCycle/reactive goldens omitted as time-dependent: acceptable; task.md line
  48 explicitly allows N/A with reason, and AC4 is covered by frame-pumping
  widget tests proven non-vacuous by the mutation probe.
- Smoke total ~30 from prior persisted runs (not a regression): confirmed —
  01-home.png shows 누적=30 at cold launch before any tap; SharedPreferences
  carries it across runs.
- Sheet dismissed by tapping a scrim offset (pumpAndSettle would time out under
  the perpetual rgbCycle animation): confirmed sensible; tests still assert the
  post-dismiss glow state.

## Findings
None. No new package dependencies (empty pubspec diff). Color picker is palette
swatches, not a third-party package, per scope.
