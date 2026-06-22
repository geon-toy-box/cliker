# QA verdict — T003

## Verdict: PASS

All evidence cited below was generated independently by QA this session under
`docs/tasks/T003/evidence/qa/`. The developer's `dev.md` was treated as an
unproven hypothesis and reproduced from a clean state.

## Independent test results
- pub get:   evidence/qa/pubget.txt — "Got dependencies!" EXIT_CODE=0
- Format:    evidence/qa/format.txt — "Formatted 16 files (0 changed)" EXIT_CODE=0
- Analyze:   evidence/qa/analyze.txt — "No issues found! (ran in 1.2s)" EXIT_CODE=0
- Unit (full):    evidence/qa/test-all.txt — "+71: All tests passed!" EXIT_CODE=0
- Unit (settings): evidence/qa/test-settings.txt — +8 passed, 0 failed, EXIT_CODE=0
- Unit (stats):    evidence/qa/test-stats.txt — +12 passed, 0 failed, EXIT_CODE=0
- Coverage:  evidence/qa/coverage.txt — overall 88.7% (159 lines); T003 files:
  settings_providers.dart 91.2%, stats_providers.dart 83.0%, settings_store.dart
  66.7%. No threshold defined in task.md (informational).
- Adversarial probe: evidence/qa/falsification-probe.txt — EXIT_CODE=0 (see below)
- Widget / Golden / Integration / Build / Runtime smoke: N/A per task.md:53-56
  (no widgets, no entrypoint change, no screen/flow). Confirmed main.dart NOT
  modified via git status (evidence/qa/scope.txt) — the N/A is real, not a skip.

Note on the running `+N` counter: in the full-suite run it reaches +71, in the
dev's run +70. This is expected — tests across files interleave in parallel so
the counter is not a stable per-test count. Authoritative counts come from the
per-file runs: 8 (settings) + 12 (stats) = 20 new tests, matching dev.md.

## Document audit
evidence/qa/doc-audit.txt — 16 claims audited, ALL BACKED. 0 UNBACKED, 0
CONTRADICTED. Every dev.md result claim reproduced to the same numbers/exit
codes; every code claim verified at file:LINE; git diff --stat matched dev.md
exactly; no undocumented changes (omission check clean).

## Adversarial probe (anti-false-green)
The AC2/AC3/AC5 "persists across a fresh ProviderContainer" tests rely on a
second `SharedPreferences.getInstance()` simulating an app restart. To rule out a
false green (where the value "survives" regardless of whether the setter actually
wrote to prefs), QA wrote a throwaway probe notifier with two setters: one that
mutates ONLY in-memory state, one that writes to prefs. Result
(evidence/qa/falsification-probe.txt, EXIT_CODE=0):
- state-only mutation → LOST across the fresh container (read back "default").
- prefs-writing mutation → SURVIVED.
This proves the harness genuinely detects non-persistence. The real setters all
write to prefs (settings_providers.dart:121,127,133,139,145;
stats_providers.dart:116,118,126,127), so their passing persistence tests are
real, not artifacts. The probe file was removed after the run; tree restored
(evidence/qa/tree-after-probe-cleanup.txt).

## Spec conformance (Acceptance criteria)
- AC1 — empty-prefs defaults: MET.
  Source settings_providers.dart:104-116 returns selectedSwitchId=
  SwitchCatalog.defaultSwitch.id ('blue', switch_type.dart:75/129), soundEnabled=true,
  hapticEnabled=true, ledMode=LedMode.ripple, ledColorArgb=
  AppColors.accentDefault.toARGB32() (accentDefault=neonCyan, app_colors.dart:38).
  Test settings_providers_test.dart:26-39 asserts every one (incl. literal 'blue').
  Stats defaults all-0 at stats_providers_test.dart:34-44. evidence/qa/test-settings.txt,
  test-stats.txt.
- AC2 — each setter persists across a FRESH container: MET.
  settings_providers_test.dart:42-110 — each of selectSwitch/setSound/setHaptic/
  setLedMode/setLedColor mutates in a first container, then a NEW ProviderContainer
  over the same mock prefs reads the value back. Probe confirms this pattern catches
  non-persistence. evidence/qa/test-settings.txt (+8, EXIT_CODE=0).
- AC3 — registerClick increments total+session; total persists, session resets: MET.
  stats_providers_test.dart:61-96 (increments by 1 each; fresh container shows
  total=2, session=0). Source stats_providers.dart:103-120 + build():88-96 sets
  sessionClicks=0 on rebuild. evidence/qa/test-stats.txt.
- AC4 — cpm = clicks in trailing-60s window; bestCpm = observed max, persists: MET.
  stats_providers_test.dart:98-178 covers window count, age-out, strict 60s
  boundary, best-holds, best-persists. Source _pruneTo (stats_providers.dart:133-138)
  is half-open: a click exactly 60s old is excluded; QA traced this and it matches
  the "strict window" test (cpm=1). Behavior is self-consistent and genuinely
  tested, not hand-waved. The half-open boundary is a deliberate, documented choice
  (dev.md:66-71) — acceptable; flagged for planner if product wants inclusive edge.
- AC5 — resetStats zeros all four AND persists (fresh container total=0, best=0): MET.
  stats_providers_test.dart:181-206; source stats_providers.dart:123-128 writes 0
  to both keys. evidence/qa/test-stats.txt.
- AC6 — analyze "No issues found!", format exit 0, pub get OK: MET.
  evidence/qa/analyze.txt, format.txt, pubget.txt — all EXIT_CODE=0.

## Scope discipline
- Only new dependency is shared_preferences ^2.5.5 (evidence/qa/scope.txt, the
  pubspec.yaml diff adds exactly one line). pubspec.lock additions are all
  shared_preferences transitive deps (evidence/qa/lock-scope.txt).
- No widgets/screens/main.dart wiring added: git status (evidence/qa/scope.txt)
  shows main.dart unmodified; only the 4 spec'd source/test files are new.

## Notes
- No findings. Persistence is verified only against the in-memory
  SharedPreferences mock (setMockInitialValues), not the real Android plugin —
  this is by design for T003 (runtime integration is deferred to T006), and
  task.md marks Build/Runtime smoke N/A. UNVERIFIED at real-device runtime, which
  is the correct status for this milestone, not a defect.

## Verdict: PASS
