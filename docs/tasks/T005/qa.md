# QA verdict — T005

All results below were produced by QA independently this session (Flutter 3.41.7
stable, Dart 3.11.5) into `docs/tasks/T005/evidence/qa/`. No developer evidence
was reused; no source, goldens, or commits were touched. The adversarial probe
test was created and then removed — the working tree was restored to its
original untracked set.

## Independent test results
- Format:      evidence/qa/format.txt — "Formatted 20 files (0 changed)", EXIT_CODE=0
- Analyze:     evidence/qa/analyze.txt — "No issues found!", EXIT_CODE=0
- Unit:        N/A per task.md (keycap logic is widget-state-bound; covered by widget tests)
- Widget:      evidence/qa/test-widget.txt — keycap_test.dart "+5: All tests passed!", EXIT_CODE=0
- Golden:      evidence/qa/test-golden.txt — keycap_golden_test.dart "+2: All tests passed!", EXIT_CODE=0
               (run WITHOUT --update-goldens — committed PNGs match this engine)
- Full suite:  evidence/qa/test-all.txt — "+78: All tests passed!", EXIT_CODE=0 (no pre-existing regression)
- Adversarial: evidence/qa/adversarial-probe.txt — "+3: All tests passed!", EXIT_CODE=0
- Goldens:     evidence/qa/goldens-ls.txt — keycap_unpressed.png 9073B, keycap_pressed.png 12429B
               (visually inspected, copies in evidence/qa/goldens-viewed/)
- Coverage:    not required by task.md (test plan scopes T005 to Format/Analyze/Widget/Golden)
- Integration / Build / Runtime smoke: N/A per task.md (single self-contained widget, no app
               entrypoint change, no flow). Correctly skipped with stated reason.

## Document audit
evidence/qa/doc-audit.txt — every code citation in dev.md verified at the exact
cited `file:LINE`; every result claim independently re-run and matched (counts,
exit codes, and golden byte sizes are EXACT matches). 0 UNBACKED, 0 CONTRADICTED.

One minor wording imprecision (NOT a failure): dev.md's "## Self-audit" pastes a
`git diff --stat`-style block, but all listed files are untracked, so a literal
`git diff --stat` emits nothing. The *substantive* claim — which files changed —
is accurate and complete: the only new/changed paths are `dart_test.yaml`,
`lib/widgets/{keycap,led_ripple}.dart`, the two golden PNGs, and the two test
files (+ dev.md itself). No undocumented source changes; main.dart / audio /
haptics / stats / pubspec untouched.

## Spec conformance
- AC1 (renders under appTheme + honors Key) → MET. keycap_test.dart:35-50 pumps
  `Keycap(key:, ledColor: neonCyan, label:'A')` under `appTheme()`, asserts the
  passed Key found, label 'A' present, `takeException()` null. evidence/qa/test-widget.txt (+1).
- AC2 (tapDown→onPressDown ×1, tapUp→onPressUp ×1, observable pressed visual) →
  MET. keycap_test.dart:52-94 uses `startGesture` (distinct down/up), asserts
  downCount==1/upCount==0 while held with `_pressScale < 1.0`, then ==1/==1 with
  scale back to ~1.0. Pressed visual is a real `Transform.scale` (keycap.dart:146,
  scale=1.0-0.06*depth). Adversarial PROBE A (evidence/qa/adversarial-probe.txt)
  proves the assertion is non-trivial: rest==1.0, pressed strictly < rest by
  >0.01, and asserting pressed==rest genuinely throws TestFailure.
- AC3 (one LedRipple per press, removed after rippleDuration, no leak) → MET.
  keycap_test.dart:96-126 asserts none before, exactly one after tapDown, still
  one after up, and `findsNothing` after `rippleDuration+1ms`. No pending-timer
  errors (suite exits 0). Adversarial PROBE B proves removal is gated on the
  FULL duration (ripple still present 10ms before, gone only after); PROBE C
  proves down spawns exactly 1 and release spawns 0.
- AC4 (two goldens, unpressed + pressed-held, dark theme + neonCyan, pass) →
  MET. keycap_golden_test.dart has 2 tagged-golden tests on a fixed 360×360 @
  DPR 1 surface, `AppColors.bg` background, `neonCyan`. Pass against committed
  PNGs without --update-goldens (evidence/qa/test-golden.txt +2). Visual review:
  both render the beveled cap; pressed golden shows a markedly stronger/tighter
  cyan glow and slightly smaller cap vs unpressed — the two states are clearly
  distinct. Label-as-white-box is documented standard harness behavior, not a defect.
- AC5 (analyze "No issues found!", format exit 0) → MET. evidence/qa/analyze.txt,
  evidence/qa/format.txt.
- Scope (no hardcoded hex in keycap.dart/led_ripple.dart; no new package deps;
  no screens/main.dart/audio/haptics/stats) → MET. grep finds zero literal
  `Color(0x..)`/`Colors.*` in either widget (all colors from AppColors / props);
  imports are only flutter material + internal theme; pubspec untouched;
  git status shows only widgets + tests + dart_test.yaml added.
- Additive `size` prop (default 240) → ACCEPTABLE. The four required props
  (ledColor required, label, onPressDown, onPressUp) all exist with the spec'd
  behavior (keycap.dart:19-26); `size` is optional and does not alter required API.

## Findings
None.

## Verdict: PASS
