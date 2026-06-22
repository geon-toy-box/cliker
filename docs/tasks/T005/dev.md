# Dev report — T005

## Summary
Built the self-contained keycap widget and its LED effects: `LedRipple` (a
one-shot expanding/fading ring that removes itself on completion) and `Keycap`
(a 3D-ish pressable cap with a fast press-down/snap-up animation, an `ledColor`
glow that intensifies while held, one `LedRipple` fired per press, and
`onPressDown`/`onPressUp` called once each). The widget knows nothing about
audio/haptics/stats — only colors and callbacks. Implemented and self-checked;
awaiting QA.

## Changes
- `lib/widgets/led_ripple.dart:11` — `LedRipple` StatefulWidget: owns its own
  `AnimationController`, plays once on mount (`forward()` in `initState`,
  `led_ripple.dart:48`), and fires `onCompleted` when the controller reaches
  `AnimationStatus.completed` (`led_ripple.dart:51`) so the parent can remove it.
  `defaultDuration = 450ms` exposed at `led_ripple.dart:31`. Ring painted by
  `_RipplePainter` (`led_ripple.dart:86`) in the passed color, wrapped in
  `IgnorePointer` so it never eats taps.
- `lib/widgets/keycap.dart:18` — `Keycap` StatefulWidget. Props exactly per spec
  (`ledColor` required, `label`, `onPressDown`, `onPressUp`); added `size`
  (default 240) so goldens/hosts can fix a stable surface. `GestureDetector`
  with `onTapDown`/`onTapUp`/`onTapCancel` (`keycap.dart:127-130`). Press
  `AnimationController` 60ms down / 90ms up (`keycap.dart:67-69`,
  `pressDownDuration`/`pressUpDuration` at `keycap.dart:47,50`). Press drives a
  `Transform.scale` (`keycap.dart:146`, scale 1.0→0.94) + downward travel + glow
  intensity. `onPressDown` called once on tapDown (`keycap.dart:89`);
  `onPressUp` called once on tapUp OR tapCancel via `_release` (`keycap.dart:106`)
  so every press is balanced. One `LedRipple` spawned per press
  (`_spawnRipple`, `keycap.dart:109`) and removed on its `onCompleted`
  (`_removeRipple`, `keycap.dart:116`). Beveled body uses
  `AppColors.keycapTop`/`keycapBase`/`keycapEdge` gradient + `ledColor`
  `BoxShadow` glow (`keycap.dart:194`); no hardcoded hex. `innerCapKey`
  (`keycap.dart:58`) exposes the pressed-state container for tests.
- `test/widget/keycap_test.dart` — 5 widget tests (AC1–AC3, see below).
- `test/widget/keycap_golden_test.dart` — 2 golden tests (AC4), tagged `golden`.
- `test/widget/goldens/keycap_unpressed.png` — golden, 9073 bytes.
- `test/widget/goldens/keycap_pressed.png` — golden, 12429 bytes.
- `dart_test.yaml` — declares the `golden` tag so `flutter test --tags golden`
  / `--exclude-tags golden` run without an "unknown tag" warning.

## Tests added
- `test/widget/keycap_test.dart` — 5 tests:
  - AC1: renders under `appTheme()`, honors a passed `Key`, shows the label, no
    exception.
  - AC2: `startGesture` tapDown → `onPressDown` exactly once and the cap scale
    drops below 1.0 (pressed visual); release → `onPressUp` exactly once and
    scale returns to 1.0.
  - AC3: each press adds exactly one `LedRipple`; after `rippleDuration` elapses
    the ripple is gone from the tree (no leak).
  - AC2/AC3 (repeat): two presses → 2 down / 2 up callbacks, no ripple left.
  - tapCancel: a press that turns into a cancel still fires `onPressUp` once
    (balanced release).
- `test/widget/keycap_golden_test.dart` — 2 tests: unpressed and pressed-held
  `Keycap` in dark theme + `AppColors.neonCyan`, fixed 360×360 surface @ DPR 1.

## Verification evidence
- Format:    evidence/dev/format.txt — `EXIT_CODE=0` ("Formatted 20 files (0 changed)")
- Analyze:   evidence/dev/analyze.txt — "No issues found!", `EXIT_CODE=0`
- Widget:    evidence/dev/test-widget.txt — keycap_test.dart "+5: All tests passed!", `EXIT_CODE=0`
- Golden:    evidence/dev/test-golden.txt — keycap_golden_test.dart "+2: All tests passed!", `EXIT_CODE=0`
- Full suite: evidence/dev/test-all.txt — "+78: All tests passed!", `EXIT_CODE=0`
  (confirms no pre-existing test regressed)
- Goldens:   evidence/dev/goldens-ls.txt — keycap_unpressed.png 9073B, keycap_pressed.png 12429B
- Diff stat: evidence/dev/diffstat.txt — 7 files changed, 658 insertions(+)
- Unit:      N/A per task.md (logic is widget-state-bound; covered by widget tests)
- Build / Integration / Runtime smoke: N/A per task.md (single widget, no app
  entrypoint change, no flow). Not run.

## AC → evidence map
- AC1 — `keycap_test.dart` "AC1: renders under appTheme honoring its Key";
  evidence/dev/test-widget.txt (+1).
- AC2 — `keycap_test.dart` "AC2: tapDown fires onPressDown once..." +
  "onTapCancel still balances..."; evidence/dev/test-widget.txt.
  Code: `keycap.dart:85-107` (callbacks), `keycap.dart:146` (pressed scale).
- AC3 — `keycap_test.dart` "AC3: each press adds exactly one LedRipple..." +
  the repeat-press test; evidence/dev/test-widget.txt.
  Code: `keycap.dart:109` (spawn), `keycap.dart:116` (remove),
  `led_ripple.dart:51-53` (self-completion).
- AC4 — `keycap_golden_test.dart` (2 goldens); generated with
  `flutter test --update-goldens` then confirmed with a plain
  `flutter test test/widget/keycap_golden_test.dart`
  (evidence/dev/test-golden.txt, +2). PNGs in evidence/dev/goldens-ls.txt.
- AC5 — evidence/dev/analyze.txt ("No issues found!") + evidence/dev/format.txt
  (`EXIT_CODE=0`).

## Self-audit
Confirmed: every claim above is backed by a file in evidence/ with a matching
`EXIT_CODE=`/result. The `## Changes` list matches `git diff --stat` for the 7
implementation/test artifacts. Working tree is left untracked (no commit run).
The stat below also includes this report file (`docs/tasks/T005/dev.md`), which
the `## Changes` list intentionally does not enumerate (a report does not list
itself as a code change) — that is the only difference, and it is expected.
Diff stat (`git add -A` then `git diff --cached --stat`, then `git reset`):

```
 dart_test.yaml                           |   6 +
 docs/tasks/T005/dev.md                   | 121 +++++++++++++++
 lib/widgets/keycap.dart                  | 253 +++++++++++++++++++++++++++++++
 lib/widgets/led_ripple.dart              | 120 +++++++++++++++
 test/widget/goldens/keycap_pressed.png   | Bin 0 -> 12429 bytes
 test/widget/goldens/keycap_unpressed.png | Bin 0 -> 9073 bytes
 test/widget/keycap_golden_test.dart      |  82 ++++++++++
 test/widget/keycap_test.dart             | 197 ++++++++++++++++++++++++
 8 files changed, 779 insertions(+)
```

## Known limitations / UNVERIFIED
- The label in the golden PNGs renders as a solid white box rather than the
  glyph "A". This is the standard `flutter_test` behavior (no real font loaded
  in the test harness renders text as filled boxes), not a defect in the widget:
  the widget test `find.text('A')` confirms a real `Text('A')` is in the tree,
  and the app ships with `uses-material-design: true` (Roboto). The goldens
  still correctly capture the cap shape, bevel/gradient, and the glow-intensity
  difference between rest and pressed, which is AC4's target surface.
- Golden pixels are host/engine-dependent. They were generated on this machine
  (Flutter 3.41.7, stable). If QA's toolchain differs, regenerate with
  `flutter test --update-goldens` — `BLOCKED:` would apply only if QA cannot run
  on a matching engine.
- Press/animation timings (60ms/90ms down/up, 450ms ripple) are taken from the
  spec; widget tests pump these exact durations, so the timing is exercised but
  the *subjective* "snap feel" is only verifiable on a device (out of scope here,
  T006).
- ASSUMPTION: added an optional `size` prop (default 240) beyond the spec's prop
  list, to fix a deterministic golden surface. It is optional and does not change
  the required API; flag for QA if the API surface must be exactly the spec list.
