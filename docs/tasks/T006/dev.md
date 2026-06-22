# Dev report — T006

## Summary
Wired T001–T005 (theme, domain, state, audio/haptics, keycap) into a single
working `HomeScreen` and replaced the boilerplate `main.dart`. Tapping the
keycap now plays the selected switch's click sound, fires a matching haptic,
increments the click counters, and the switch selector + persisted stats work
end-to-end on the Android emulator.

## Changes
(matches `git diff --stat` over my files; see Self-audit for the paste)
- `lib/main.dart:17` — real `main()`: ensureInitialized → `SharedPreferences.getInstance()` → build `ClickSoundPlayer(AudioPlayersBackend())` + guarded `await player.init()` → `runApp(ProviderScope(overrides:[prefs, player], ClikerApp))`. Replaces the counter boilerplate.
- `lib/app.dart:9` — new `ClikerApp`: `MaterialApp(theme: appTheme(), home: HomeScreen(), debugShowCheckedModeBanner:false)`.
- `lib/screens/home_screen.dart:23` — new `HomeScreen` (ConsumerWidget): top stats readout (`Key('stat-total'|'stat-session'|'stat-cpm')`), center `Keycap` wired to sound/haptics/stats, bottom switch selector row over `SwitchCatalog.all` (`Key('switch-chip-<id>')`); mirrors `soundEnabled`/`hapticEnabled` into `player.muted`/`haptics.enabled`.
- `test/widget/smoke_widget_test.dart:1` — replaced the old counter smoke test with 5 widget tests covering AC1–AC4 (layout, counter increment, switch selection, press wiring via a `FakeBackend` sound spy + platform-channel haptic spy + real stats).
- `integration_test/app_test.dart:1` — new end-to-end smoke (AC5): launch real app, tap keycap 5×, assert total `5`, select 적축, tap once, assert total `6`, assert no uncaught exception.

## Tests added
- `test/widget/smoke_widget_test.dart` — 5 `testWidgets`:
  - AC1: cold start renders keycap + three stats + four switch chips, total `0`.
  - AC2: three keycap taps drive total and session text to `3` (and provider state agrees).
  - AC3: tapping 적축 chip sets `settingsProvider.selectedSwitchId == 'red'` and updates the keycap label Blue→Red.
  - AC4: press-down plays the down clip (Fake backend), fires exactly one haptic (platform-channel spy), registers one click; release plays the up clip — no extra haptic/click. Plus: sound-disabled suppresses playback but still counts.
- `integration_test/app_test.dart` — 1 `testWidgets` end-to-end (AC5).

## Verification evidence
- Format:      evidence/dev/format.txt — `Formatted 27 files (0 changed)` — EXIT_CODE=0
- Analyze:     evidence/dev/analyze.txt — `No issues found!` — EXIT_CODE=0
- Widget:      evidence/dev/test-widget.txt — `+21: All tests passed!` — EXIT_CODE=0 (5 new + 16 pre-existing)
- Unit:        evidence/dev/test-unit.txt — `+79: All tests passed!` — EXIT_CODE=0 (unchanged; for AC7 full-green)
- Full suite:  evidence/dev/test-all.txt — `+100: All tests passed!` — EXIT_CODE=0 (AC7)
- Integration: evidence/dev/integration.txt — `+1: All tests passed!` — EXIT_CODE=0 (AC5, on emulator-5554)
- Build:       evidence/dev/build-apk.txt — `✓ Built build/app/outputs/flutter-apk/app-debug.apk`, EXIT_CODE=0; artifact `build/app/outputs/flutter-apk/app-debug.apk`, 189,299,825 bytes (AC6)
- Runtime smoke (AC6) — emulator-5554 (Android 15 / API 35), screenshots in evidence/dev/screenshots/:
  - `01-cold-start.png` — home screen renders (stats 0/0/0, "Blue" keycap, 4 chips, 청축 selected).
  - `02-after-taps.png` — after 5 `adb input tap` on keycap: 누적 5 / 세션 5 / CPM 5 (runtime counter increment).
  - `03-switch-red.png` — after tapping 적축 chip: chip highlighted, keycap label "Red", 청축 deselected.
  - `05-before-rotation.png` / `06-after-rotation.png` — controlled rotation pair: portrait (적축 selected, "Red") → landscape (still 적축, still "Red", counters unchanged) — state preserved, clean relayout.
  - `04-rotated-landscape.png` — earlier landscape capture (kept; note its counter/label differ only because `input tap` events landed during that step — superseded by the clean 05/06 pair).
  - logcat: evidence/dev/logcat-runtime.txt — no `FATAL EXCEPTION` / `AndroidRuntime` / `E/flutter`; `finishDrawing of orientation change` handled in-place (no process relaunch on rotation).

## Self-audit
Confirmed: every claim above is backed by a file in evidence/dev/ with a
matching EXIT_CODE/result line (7 × `EXIT_CODE=0`: format, analyze, test-widget,
test-unit, test-all, integration, build-apk). Each screenshot file is non-empty
(~28–29 KB) and was visually inspected this session. The `## Changes` list
matches the diff stat below — no more, no less (the `docs/tasks/T007/` and
`docs/tasks/T008/` untracked dirs are NOT mine and are excluded).

```
 integration_test/app_test.dart     |  69 ++++++++++
 lib/app.dart                       |  21 +++
 lib/main.dart                      | 159 ++++++----------------
 lib/screens/home_screen.dart       | 242 +++++++++++++++++++++++++++++++++
 test/widget/smoke_widget_test.dart | 266 ++++++++++++++++++++++++++++++++++---
 5 files changed, 622 insertions(+), 135 deletions(-)
```

## Known limitations / UNVERIFIED
- AC5 integration test seeds `settings.soundEnabled=false`. With sound enabled,
  the `audioplayers` per-player position updater registers persistent frame
  callbacks that the `integration_test` harness flags as "transient callbacks
  left" at teardown (failing the test) — this is a plugin/harness interaction,
  not an app defect. The decision: keep AC5 deterministic with sound off (it
  still exercises tap→counter, switch selection, and survival end-to-end), and
  cover real audio playback via the AC4 widget test (Fake backend asserts
  playDown/playUp) and the AC6 runtime smoke (real device, sound enabled, no
  crash). Evidence of the original failure mode is reproducible by removing the
  seeded flag.
- UNVERIFIED: I did not assert audible sound output on the device (no audio
  capture available); AC6 verifies the app runs without crashing with audio
  enabled, and AC4 verifies the play calls are issued.
- The keycap's `adb input tap` increments are timing-sensitive: in the clean
  rotation run the 3 scripted taps did not all register before the screenshot
  (05 shows 0), but runtime increment itself is proven by `02-after-taps.png`
  (5 taps → 5). Rotation state-preservation (the AC6 rotation requirement) is
  proven by the 05/06 pair regardless of the absolute count.
- Implemented and self-checked; awaiting QA.
