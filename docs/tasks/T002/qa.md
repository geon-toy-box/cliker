# QA verdict — T002

Switch domain catalog + synthesized switch sound assets. All claims below rest on
evidence QA generated this session under `docs/tasks/T002/evidence/qa/`. The
developer's `dev.md` was treated as a hypothesis and independently falsified.

## Verdict: PASS

## Independent test results
- Format:    `evidence/qa/format.txt` — `Formatted 11 files (0 changed)`, EXIT_CODE=0
- Analyze:   `evidence/qa/analyze.txt` — `No issues found!`, EXIT_CODE=0
- Unit:      `evidence/qa/test-unit.txt` — `+50: All tests passed!` (test/unit), EXIT_CODE=0
- Full suite:`evidence/qa/test-full.txt` — `+51: All tests passed!` (incl. pre-existing widget smoke), EXIT_CODE=0
- Widget:    N/A per task.md §Test plan (no widgets in this task)
- Golden:    N/A per task.md §Test plan (no render surface)
- Coverage:  N/A — task.md test plan does not require a coverage gate for this assets/domain task
- Integration: N/A per task.md §Test plan (no flow)
- Build:     N/A per task.md §Test plan (assets-only, no entrypoint change; `flutter pub get` resolution suffices — `evidence/qa/pubget.txt`, `Got dependencies!`, EXIT_CODE=0)
- Smoke:     N/A per task.md §Test plan (no runtime surface; playback is T004)

New-test accounting: the two new files contribute 35 tests
(`switch_catalog_test.dart` 10 + `switch_assets_test.dart` 25), matching dev.md.
Suite total 51, none failed.

## Document audit
`evidence/qa/doc-audit.txt` — 14 claims audited, **14 BACKED, 0 UNBACKED, 0 CONTRADICTED**.
File set independently confirmed 13 files (`evidence/qa/filecount-audit.txt`,
`evidence/qa/git-audit.txt`); all WAV byte-sizes in dev.md match `ls -l`
(`evidence/qa/wav-headers-xxd.txt`). The dev's disclosed AC4 limitation (literal
`git status --porcelain` only empties post-commit) is accurate and honestly stated.

## Spec conformance (AC1–AC6 from task.md)

- **AC1 (catalog shape)** → MET. `lib/domain/switch_type.dart:126` `all=[blue,brown,red,black]`
  in order; ids unique; nameKo/nameEn/description non-empty (`:74-123`); each `stemColor`
  references `AppColors.switch*` not a hex literal (`:79,:92,:105,:118`); each `defaultLed`
  (`neonCyan/neonOrange/neonMagenta/neonGreen`) is a member of `AppColors.ledPalette`
  (`lib/theme/app_colors.dart:42-49`); every `hapticStrength` ∈ (0,1] (1.0/0.7/0.45/0.6).
  Unit tests assert all of these (`test/unit/switch_catalog_test.dart:8-67`), passing in
  `evidence/qa/test-unit.txt`.

- **AC2 (lookup)** → MET. `byId('red')`→red, `byId('bogus')` and `byId('')`→`defaultSwitch`
  (`switch_type.dart:132-139`); `defaultSwitch == all.first` (blue) (`:129`). Asserted by
  `switch_catalog_test.dart:70-86`, passing in `evidence/qa/test-unit.txt`.

- **AC3 (8 valid WAV assets)** → MET. All 8 files exist and are > 1KB (`evidence/qa/wav-headers-xxd.txt`
  `ls -l`: sizes 6218–13716 B). The unit test opens each `downAsset`/`upAsset` via `File`,
  asserts exist/>1KB, and byte-parses the RIFF/WAVE header for audioFormat=1, channels=1,
  sampleRate=44100, bitsPerSample=16 (`test/unit/switch_assets_test.dart:26-108`), passing.
  QA INDEPENDENTLY spot-checked headers: `xxd` of blue_down/black_down/red_up shows
  `RIFF…WAVE`, fmt chunk = 16, audioFormat=1, channels=1, rate=0xAC44=44100, bits=16
  (`evidence/qa/wav-headers-xxd.txt`); and a full `python3 wave` parse of all 8 confirms
  ch=1, sampwidth=2, rate=44100, durations 70–155ms within the 60–160ms spec
  (`evidence/qa/wav-parse-python.txt`). Genuinely mono/44100/16-bit, not a weak pass.

- **AC4 (committed, stdlib-only, deterministic)** → MET (determinism intent). `tools/gen_sounds.py`
  imports only stdlib `math/os/random/struct/wave` (`:30-34`), no numpy/third-party
  (`evidence/qa/stdlib-and-bytecmp.txt` grep). QA ran `python3 tools/gen_sounds.py` twice
  (`evidence/qa/gen-rerun.txt`, GEN1_EXIT=0/GEN2_EXIT=0); resulting SHA-256 for all 8 WAVs
  equal each other AND the dev-generated originals — `diff` empty, DIFF_EXIT_CODE=0
  (`evidence/qa/hashes-original.txt`, `hashes-rerun.txt`, `hashes-diff.txt`), and `cmp`
  reports all 8 byte-IDENTICAL (`evidence/qa/stdlib-and-bytecmp.txt`, CMP_EXIT=0). The
  literal `git status --porcelain assets/sounds` empty check cannot pass for untracked
  files; per QA brief, the stronger byte-equality proof satisfies the determinism intent.
  (`random.seed`-fixed; verified on CPython 3.14.5 only — noted, not a blocker.)

- **AC5 (pubspec registration, no new dep)** → MET. `pubspec.yaml:64-65` registers
  `assets/sounds/` under `flutter: assets:`; `git diff pubspec.yaml` shows ONLY that block
  added — no dependency change — and `pubspec.lock` is unchanged (no new package resolved)
  (`evidence/qa/pubspec-audit.txt`, `git-audit.txt`). `flutter pub get` resolves cleanly
  (`evidence/qa/pubget.txt`, `Got dependencies!`, EXIT_CODE=0).

- **AC6 (analyze + format clean)** → MET. `flutter analyze` → `No issues found!`, EXIT_CODE=0
  (`evidence/qa/analyze.txt`); `dart format --set-exit-if-changed .` → 0 changed, EXIT_CODE=0
  (`evidence/qa/format.txt`).

## Findings
None. Every applicable test-pyramid layer passed on QA's own evidence, the document
audit is fully BACKED, and all six acceptance criteria are met.

## Notes
- Working tree restored: QA's regeneration produced byte-identical files, so the
  dev-generated WAVs on disk are unchanged (`black_down.wav` SHA-256 still
  `36b6362…368fade`). The `_orig_backup` helper dir was removed.
- N/A test-pyramid layers (widget/golden/coverage/integration/build/smoke) are
  justified by task.md's explicit Test plan, not silently skipped.
- Audio *quality* (how clips sound) is out of scope here; only format/length/determinism
  verified. Playback is T004.

Status: VERIFIED
