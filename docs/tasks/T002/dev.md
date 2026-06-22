# Dev report — T002

## Summary
Built the switch catalog domain model (`lib/domain/switch_type.dart`: `SwitchType`
+ `SwitchCatalog` with the four switches blue/brown/red/black in order) and a
deterministic, stdlib-only Python synthesizer (`tools/gen_sounds.py`) that
generated the 8 bundled WAV clips into `assets/sounds/`, then registered that
folder in `pubspec.yaml`. Implemented and self-checked; awaiting QA.

## Changes
Matches `git diff --stat` exactly (see Self-audit). 13 files:
- `lib/domain/switch_type.dart:1` — new. `SwitchType` (id-keyed equality,
  `@immutable`, const ctor) + `SwitchCatalog` (`all`=[blue,brown,red,black],
  `byId`, `defaultSwitch`=blue). Colors sourced from `AppColors` (no hex).
- `pubspec.yaml:64` — registered `assets/sounds/` under `flutter: assets:`
  (assets only; no new package dependency).
- `tools/gen_sounds.py:1` — new. Deterministic synthesizer (stdlib: math, os,
  random, struct, wave at `:30-34`). Fixed seed `RANDOM_SEED = 20260622` at
  `:40`. Header comment documents regeneration: `python3 tools/gen_sounds.py`
  at `:9`.
- `assets/sounds/blue_down.wav` — new (9746 B)
- `assets/sounds/blue_up.wav` — new (6660 B)
- `assets/sounds/brown_down.wav` — new (10628 B)
- `assets/sounds/brown_up.wav` — new (7100 B)
- `assets/sounds/red_down.wav` — new (9304 B)
- `assets/sounds/red_up.wav` — new (6218 B)
- `assets/sounds/black_down.wav` — new (13716 B)
- `assets/sounds/black_up.wav` — new (8424 B)
- `test/unit/switch_catalog_test.dart:1` — new. AC1 + AC2 coverage.
- `test/unit/switch_assets_test.dart:1` — new. AC3 coverage (byte-level WAV
  header parser).

## Tests added
- `test/unit/switch_catalog_test.dart` — 10 tests.
  - AC1: order `[blue,brown,red,black]`, unique ids, non-empty
    nameKo/nameEn/description, `stemColor == AppColors.switch*`,
    `defaultLed ∈ AppColors.ledPalette`, `hapticStrength ∈ (0,1]`.
  - AC2: `byId('red'|'blue'|'brown'|'black')` returns the match; `byId('bogus')`
    and `byId('')` return `defaultSwitch`; `defaultSwitch == all.first` (blue).
  - Plus: `SwitchType` `==`/`hashCode` are keyed on `id`.
- `test/unit/switch_assets_test.dart` — 25 tests.
  - AC3: 8 clips enumerated from `SwitchCatalog.all` downAsset/upAsset; each
    opened as a `File` and asserted to exist, be > 1KB, and parse as a valid
    WAV header (RIFF/WAVE magic, fmt: audioFormat=1 PCM, channels=1,
    sampleRate=44100, bitsPerSample=16). Header parsed from raw bytes (no
    `dart:io` WAV helper) by walking RIFF chunks to find `fmt `.

## Verification evidence
- Format:    `evidence/dev/format.txt` — `Formatted 11 files (0 changed)`, EXIT_CODE=0
- Analyze:   `evidence/dev/analyze.txt` — `No issues found!`, EXIT_CODE=0
- Test (all):`evidence/dev/test.txt` — `+51: All tests passed!`, EXIT_CODE=0
  (whole suite; includes 35 new tests across the two new files)
- Pub get:   `evidence/dev/pubget.txt` — `Got dependencies!`, EXIT_CODE=0
- Determinism (AC4): `evidence/dev/gen-determinism.txt` — two independent runs
  produce identical SHA-256 for all 8 WAVs; `diff` of the two hash listings is
  empty (DIFF_EXIT_CODE=0); after staging + re-run the unstaged worktree diff
  for `assets/sounds` is empty (worktree == index byte-for-byte).
- Diff stat: `evidence/dev/git-diff-stat.txt` — 13 files changed, 617
  insertions(+), EXIT_CODE=0.

### AC → evidence map
- AC1 (catalog): `test/unit/switch_catalog_test.dart` (group "SwitchCatalog.all
  (AC1)") → `lib/domain/switch_type.dart:74-123` (catalog entries) +
  `:126` (`all`). Evidence: `evidence/dev/test.txt` (+51 pass).
- AC2 (lookup): `test/unit/switch_catalog_test.dart` (group "SwitchCatalog
  lookup (AC2)") → `lib/domain/switch_type.dart:129` (`defaultSwitch`),
  `:132` (`byId`). Evidence: `evidence/dev/test.txt`.
- AC3 (assets valid WAV): `test/unit/switch_assets_test.dart` (group "Switch
  sound assets exist and are valid WAV (AC3)") → the 8 files in
  `assets/sounds/`. Evidence: `evidence/dev/test.txt`.
- AC4 (deterministic, stdlib-only): `tools/gen_sounds.py:30-34` (imports:
  math/os/random/struct/wave only), `:40` (`RANDOM_SEED`), `:9` (regen
  comment). Evidence: `evidence/dev/gen-determinism.txt`.
- AC5 (pubspec + pub get): `pubspec.yaml:64-65`. Evidence: `evidence/dev/pubget.txt`.
- AC6 (analyze/format): Evidence: `evidence/dev/analyze.txt`, `evidence/dev/format.txt`.

## Test pyramid applicability (per task.md Test plan)
- Format: done (EXIT_CODE=0).
- Analyze: done (`No issues found!`).
- Unit: done (+51 all pass; 35 new).
- Widget: N/A — no widgets in this task (task.md §Test plan).
- Golden: N/A — no render surface (task.md §Test plan).
- Integration: N/A — no flow (task.md §Test plan).
- Build: N/A — no entrypoint change, assets-only; pub get resolution suffices
  (task.md §Test plan). UNVERIFIED: no `flutter build` run this session, per the
  task's explicit N/A.
- Runtime smoke: N/A — no runtime surface; playback is T004 (task.md §Test plan).

## Self-audit
Confirmed: every claim above is backed by a file in `evidence/dev/` with a
matching EXIT_CODE/result, all generated this session. `git diff --stat` matches
the Changes list exactly (13 files). Pasted stat:

```
 assets/sounds/black_down.wav       | Bin 0 -> 13716 bytes
 assets/sounds/black_up.wav         | Bin 0 -> 8424 bytes
 assets/sounds/blue_down.wav        | Bin 0 -> 9746 bytes
 assets/sounds/blue_up.wav          | Bin 0 -> 6660 bytes
 assets/sounds/brown_down.wav       | Bin 0 -> 10628 bytes
 assets/sounds/brown_up.wav         | Bin 0 -> 7100 bytes
 assets/sounds/red_down.wav         | Bin 0 -> 9304 bytes
 assets/sounds/red_up.wav           | Bin 0 -> 6218 bytes
 lib/domain/switch_type.dart        | 140 ++++++++++++++++++++
 pubspec.yaml                       |   4 +
 test/unit/switch_assets_test.dart  | 110 ++++++++++++++++
 test/unit/switch_catalog_test.dart | 107 ++++++++++++++++
 tools/gen_sounds.py                | 256 +++++++++++++++++++++++++++++++++++++
 13 files changed, 617 insertions(+)
```

## Known limitations / UNVERIFIED
- AC4 exact git form: task.md asks that after re-running `python3 tools/gen_sounds.py`,
  `git status --porcelain assets/sounds` be empty. That literal form only holds
  once the WAVs are committed (for untracked files, porcelain lists them
  regardless of content). The hard rules forbid me from committing, so I proved
  byte-level determinism the stronger way: identical SHA-256 across two
  independent runs (empty `diff`, DIFF_EXIT_CODE=0) and an empty unstaged
  worktree diff after staging + re-run. After the worker commits the WAVs, the
  exact porcelain-empty check is reproducible. See
  `evidence/dev/gen-determinism.txt`.
- Determinism is verified only on this machine's interpreter
  (Python 3.14.5, CPython). `random.Random(seed)` + the fixed float math used
  here are stable across CPython versions, but I did not test other interpreters
  this session.
- No `flutter build` was run (task.md marks Build N/A for this assets-only task).
- Audio quality / how the clips actually *sound* is not verified — only that
  they are well-formed WAVs of the right format and length. Playback is T004.
