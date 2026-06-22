# Dev report — T003

Status: implemented and self-checked; awaiting QA.

## Summary
Added `shared_preferences`-backed persistence and the Riverpod state on top of
it: a `Settings` notifier (selected switch, sound/haptic toggles, LED mode, LED
color) and a `Stats` notifier (lifetime total + best CPM persisted; session
clicks and live CPM in-memory with a trailing-60s window). No UI/audio — only
the store, providers, and their unit tests, per spec scope.

## Changes
Tracked files (`git diff --stat`):
- `pubspec.yaml:38` — added `shared_preferences: ^2.5.5` (the only new dep).
- `pubspec.lock` — resolver output for the new dep + its transitive packages.

New (untracked) files:
- `lib/persistence/settings_store.dart` — `sharedPreferencesProvider`
  (`Provider<SharedPreferences>` that throws until overridden in `main`/tests).
- `lib/providers/settings_providers.dart` — `enum LedMode {ripple, solid,
  rgbCycle, reactive}`; `Settings` (copyWith + value equality); `SettingsNotifier
  extends Notifier<Settings>` reading defaults from prefs in `build()` and
  persisting on each setter (`selectSwitch`, `setSound`, `setHaptic`,
  `setLedMode`, `setLedColor`); `settingsProvider`.
- `lib/providers/stats_providers.dart` — `Stats` (copyWith + value equality);
  `StatsNotifier extends Notifier<Stats>` with `registerClick(DateTime now)`,
  `resetStats()`; `statsProvider`. `totalClicks`/`bestCpm` persisted,
  `sessionClicks`/`cpm` in-memory.
- `test/unit/settings_providers_test.dart` — settings unit tests.
- `test/unit/stats_providers_test.dart` — stats unit tests.

Note: the new `lib/` and `test/` files are untracked, so they do not appear in
`git diff --stat` (which lists only modifications to tracked files). They show as
`??` in `git status`. The full reconciliation is in Self-audit below.

## Tests added
8 test functions in `test/unit/settings_providers_test.dart`:
- AC1: defaults from empty prefs (switch=blue, sound/haptic=true,
  ledMode=ripple, ledColorArgb=`AppColors.accentDefault.toARGB32()`).
- AC2: `selectSwitch`/`setSound`/`setHaptic`/`setLedMode`/`setLedColor` each
  persist across a fresh `ProviderContainer` over the same mock prefs.
- value semantics: `copyWith`, `==`/`hashCode`.

12 test functions in `test/unit/stats_providers_test.dart`:
- AC1/AC3: empty-prefs defaults all 0; loads persisted total/best; `registerClick`
  increments total+session; total persists across restart while session resets.
- AC4: CPM counts clicks in the trailing 60s window; clicks aging past 60s drop;
  a click exactly 60s old is excluded (strict window); `bestCpm` tracks the
  observed max then holds; `bestCpm` persists across restart.
- AC5: `resetStats` zeroes all four and the persisted total/best survive restart.
- value semantics: `copyWith`, `==`/`hashCode`.

## Verification evidence
- pub add:  `evidence/dev/pubget.txt` — EXIT_CODE=0 (`+ shared_preferences 2.5.5`)
- Format:   `evidence/dev/format.txt` — `Formatted 16 files (0 changed)` EXIT_CODE=0
- Analyze:  `evidence/dev/analyze.txt` — `No issues found!` EXIT_CODE=0
- Unit:     `evidence/dev/test.txt` — `All tests passed!` EXIT_CODE=0 (whole
  `test/unit` suite green: 32 pre-existing + the 20 new functions above; the
  runner's `+N` counter advances per assertion-yield so its final `+70` is not a
  test count — the authoritative signal is `All tests passed!` + EXIT_CODE=0 with
  every named test from both new files listed).
- Widget:  N/A per spec (no widgets in this task).
- Golden / Integration / Build / Runtime smoke: N/A per spec §"Test plan"
  (no entrypoint change, no screen/flow; providers verified by unit tests).

## CPM windowing decision (UNVERIFIED beyond unit tests)
The trailing window is computed from in-memory click timestamps kept in a queue;
on each `registerClick(now)` timestamps `<= now - 60s` are pruned and `cpm` is
the remaining count. The window is **half-open**: a click exactly 60s old is
excluded (covered by the "strict window" test). This is a deliberate boundary
choice — flag for planner/QA if the product wants an inclusive 60s edge.
ASSUMPTION: clicks always arrive with non-decreasing timestamps (real input from
the UI clock); the prune logic does not reorder out-of-order timestamps.

## Self-audit
- `git diff --stat` (tracked) =
  `pubspec.lock | 111 +-`, `pubspec.yaml | 1 +`, "2 files changed, 111
  insertions(+), 1 deletion(-)". This matches the two tracked entries in Changes.
- The five new source/test files are untracked (`git status`: `?? lib/persistence/`,
  `?? lib/providers/`, `?? test/unit/settings_providers_test.dart`,
  `?? test/unit/stats_providers_test.dart`). I did NOT `git add`/commit (per
  dispatch rule). Every file in the Changes list is either in the diff stat or in
  this untracked list — no more, no less.
- Each result claim above cites a file in `evidence/dev/` carrying an
  `EXIT_CODE=` line that I generated this session.

## Known limitations / UNVERIFIED
- No build/runtime evidence (N/A per spec — no entrypoint/screen). The providers
  are unverified against a real app launch; that integration lands in T006.
- `main` does not yet override `sharedPreferencesProvider` (out of scope here);
  reading `settingsProvider`/`statsProvider` without that override throws by
  design. UNVERIFIED at runtime until a later task wires `main`.
- Persistence is verified only via `SharedPreferences.setMockInitialValues`
  (in-memory mock), not against the real Android plugin.
