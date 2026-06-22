# QA verdict — T006

All results below were produced by QA this session via independent re-run, into
`docs/tasks/T006/evidence/qa/` (a separate subtree from the developer's). No
result here rests on the developer's numbers; each was reproduced.

## Verdict: PASS

## Independent test results
- Format:      evidence/qa/format.txt — `Formatted 27 files (0 changed)` — EXIT_CODE=0
- Analyze:     evidence/qa/analyze.txt — `No issues found! (ran in 1.6s)` — EXIT_CODE=0
- Unit:        evidence/qa/test-unit.txt — `+79: All tests passed!` — EXIT_CODE=0
- Widget:      evidence/qa/test-widget.txt — `+21: All tests passed!` (5 new AC1–AC4 + 16 pre-existing) — EXIT_CODE=0
- Golden:      N/A per task.md (individual surfaces golden-tested in T005; screen assembly covered by widget tests). The keycap golden ran inside the widget/full suites and passed.
- Full suite:  evidence/qa/test-all.txt — `+100: All tests passed!` — EXIT_CODE=0
- Coverage:    N/A — task.md does not set a coverage gate for this integration task; logic was unit-covered in T003. Not run.
- Integration: evidence/qa/test-integration.txt — `+1: All tests passed!` on emulator-5554 — EXIT_CODE=0
- Build:       evidence/qa/build.txt — artifact `build/app/outputs/flutter-apk/app-debug.apk`, 189,299,825 bytes (ls -l confirmed on disk) — EXIT_CODE=0
- Smoke:       evidence/qa/smoke/01-cold-start.png … 07-back-to-portrait.png + evidence/qa/logcat.txt — no FATAL/AndroidRuntime/E/flutter (grep GREP_EXIT=1, no match); pid 6168 stable across the full rotation cycle.

## Document audit
evidence/qa/doc-audit.txt — 13 claims audited: 13 BACKED, 0 UNBACKED, 0 CONTRADICTED.
One minor imprecision (not a failure): dev.md's Self-audit says its 5-file
diff-stat "matches `git diff --stat`", but bare `git diff --stat` this session
shows only the 2 tracked-modified files; the other 3 are new untracked files
(`lib/app.dart`, `lib/screens/home_screen.dart`, `integration_test/app_test.dart`)
that only appear after staging. The substance is true — `git status --short`
confirms exactly that 5-file set, no undocumented source change, no dep change.
DOC AUDIT: PASS.

## Spec conformance (each AC verified with QA evidence)
- AC1 (cold start layout) → MET. evidence/qa/smoke/01-cold-start.png shows centered
  "Blue" keycap, stats readout (누적 0 / 세션 0 / CPM 0), and four switch chips
  (청축 selected, 갈축, 적축, 흑축). Widget test "HomeScreen layout (AC1)" asserts
  Keycap + three stat keys + one chip per SwitchCatalog switch + total '0'
  (smoke_widget_test.dart:111-136), passed in evidence/qa/test-widget.txt.
- AC2 (counter increment) → MET. Widget test "three taps drive total and session
  to 3" asserts both rendered text == '3' AND provider state == 3
  (smoke_widget_test.dart:140-164). Runtime: evidence/qa/smoke/02-after-taps.png
  shows 6 taps → 누적 6 / 세션 6.
- AC3 (switch selection) → MET. Widget test "tapping 적축 selects red" asserts
  settingsProvider.selectedSwitchId == 'red' AND keycap label Blue→Red
  (smoke_widget_test.dart:168-188). Runtime: evidence/qa/smoke/03-switch-red.png
  shows 적축 chip highlighted (red border/glow) and keycap label "Red".
- AC4 (press wiring) → MET. Widget test asserts press-down → backend.played
  hasLength(1) with soundId == downId, vibrateArgs hasLength(1), total '1';
  release → played hasLength(2) with upId, no extra haptic/click
  (smoke_widget_test.dart:192-228). These are strict equality assertions on a
  Fake backend + platform-channel haptic spy + real stats — a missing call would
  flip the length/id check and FAIL the test (verified by reading the test, not a
  no-op). A second AC4 test confirms sound-disabled suppresses playback yet still
  counts (:230-255). All passed in evidence/qa/test-widget.txt.
- AC5 (integration end-to-end) → MET. QA independently ran
  `flutter test integration_test/app_test.dart -d emulator-5554`: +1 passed,
  EXIT_CODE=0 (evidence/qa/test-integration.txt). Test taps keycap 5× → total '5',
  selects 적축, taps once → total '6', asserts takeException() isNull
  (app_test.dart:31-68). The `soundEnabled:false` seed is ONLY in this test's
  setMockInitialValues (app_test.dart:36-38) and does NOT change shipped behavior
  (see sound-default note below).
- AC6 (build + runtime smoke incl. rotation) → MET. `flutter build apk --debug`
  succeeded, artifact on disk (evidence/qa/build.txt). QA's own runtime smoke on
  emulator-5554 (clean install, fresh data): cold start renders (01), taps
  increment counter (02: →6), switch change works (03: →Red/적축), ROTATE to
  landscape → NO crash, full state preserved (05: 누적/세션/CPM all 6, Red, 적축
  highlighted, clean landscape relayout), interactive after rotation (06: tap →7),
  rotate back to portrait, state preserved (07: 7/7). pid 6168 unchanged across
  the whole cycle (no process relaunch). logcat clean of FATAL/AndroidRuntime/
  E/flutter.
- AC7 (analyze/format/full test green) → MET. format EXIT_CODE=0, analyze
  "No issues found!", full suite +100 EXIT_CODE=0 (above). Boilerplate counter
  smoke test replaced — confirmed gone (no MyApp/MyHomePage/incrementCounter in
  lib/main.dart or test/), new AC1–AC4 tests present and passing.

## Scope
- No new package deps: `git diff pubspec.yaml` is empty (riverpod /
  shared_preferences / audioplayers were already present from T001–T005).
- Settings/stats wiring reuses existing providers: home_screen.dart watches
  settingsProvider / statsProvider / clickSoundPlayerProvider / hapticsProvider
  and calls existing methods (selectSwitch, registerClick, playDown/playUp,
  haptics.click) — no logic reimplemented (home_screen.dart:33-59).

## Shipped sound default: ON (confirmed)
The product ships with sound ENABLED. settings_providers.dart:110 —
`soundEnabled: prefs.getBool(_keySoundEnabled) ?? true`. On a clean install +
interaction, the on-device prefs (evidence/qa/device-prefs.txt) contain
stats.totalClicks=7, stats.bestCpm=6, settings.selectedSwitchId=red, and NO
settings.soundEnabled key — so the running app falls back to the code default
`true`. The integration test's `soundEnabled:false` is a deterministic
test-harness accommodation (avoids the audioplayers transient-callback teardown
flag), confined to the test's seeded prefs; it is NOT a shipped behavior change.

## Notes
- Coverage and golden layers are N/A for this task per task.md's test-plan
  section, which assigns visual goldens to T005 and unit logic to T003; this task
  is verified by widget + integration + runtime smoke. Stated explicitly rather
  than silently skipped.
- dev.md's diff-stat description imprecision (above) is the only blemish and does
  not affect correctness; flagged for the developer's awareness, not a failure.
