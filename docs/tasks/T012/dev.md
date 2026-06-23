# Dev report — T012 (스위치 11종 확장 + UI 개편)

## Summary
Expanded the switch catalog from 4 to the exact 11 spec switches (adding a
`SwitchKind` enum plus `kind`/`forceCn` fields and 7 new `AppColors` stem
tokens), extended the deterministic sound synthesizer to emit 22 WAVs, rebuilt
the stats panel to show exactly two figures (전체 클릭수 + RPM), redesigned the
keycap into a sculpted 3D cap with a pronounced press, and turned the switch
selector into a horizontally-scrollable row of all 11 chips. Implemented and
self-checked across the full test pyramid + an on-device smoke run; awaiting QA.

## Changes
(Matches the set of source files modified this session; no git in this tree, so
reconciled via `find … -newermt` + the asset/golden listing — see Self-audit.)

- `lib/theme/app_colors.dart:36-42` — added 7 new switch-stem tokens
  (`switchWhite`/`switchGray`/`switchClear`/`switchSilentRed`/`switchSilentBlack`/`switchSpeedSilver`/`switchDarkGray`)
  with the exact spec hex. (A)
- `lib/domain/switch_type.dart` — added `enum SwitchKind { clicky, tactile, linear }`
  (L11-16), `kind`/`forceCn` fields on `SwitchType` (ctor + fields), and expanded
  `SwitchCatalog.all` to the exact 11 switches in spec order with all fields;
  `defaultSwitch`/`byId` unchanged. (A)
- `tools/gen_sounds.py` — added synth params for the 7 new switches (timbre
  derived from kind: clicky≈blue, tactile≈brown/clear, linear≈red/black; silent =
  lower peak + darker; speed = shorter; 80cN = low-end emphasis), extended
  `SWITCH_ORDER` to 11; kept the single fixed seed so output is deterministic. (B)
- `lib/widgets/stats_panel.dart` — rewritten: a single Row with exactly two
  `_StatTile`s — `stat-total` (전체 클릭수) and `stat-rpm` (RPM = `stats.cpm`) —
  plus a small reset `IconButton` → confirm dialog → `resetStats()`. Removed the
  session/cpm/best tiles and their keys. (C)
- `lib/widgets/keycap.dart` — redesigned the cap: dished rounded top face on a
  visible side skirt over a floor shadow. Press now travels the top face down
  (`size*0.075` ≈ 18px at default size, ≥10px bar), shrinks it, compresses the
  skirt, shrinks the floor shadow, and flares the glow; snaps back on release.
  Public API (`ledColor`/`ledMode`/`label`/`onPressDown`/`onPressUp`/`size`),
  `innerCapKey`, and the glow-`BoxShadow`-first contract preserved. (D)
- `lib/screens/home_screen.dart` — re-exported `rpmStatKey` (dropped
  `sessionStatKey`/`cpmStatKey`); selector now a horizontal `SingleChildScrollView`
  + `Row` of all 11 `_SwitchChip`s (all built at once so every chip key is in the
  tree), selected chip shows `kind · forceCn`. Keycap label still = selected
  `nameEn`. (E)

Tests updated (broken by the catalog/panel/keycap changes):
- `test/unit/switch_catalog_test.dart` — rewritten: asserts all 11 switches
  row-for-row incl. `kind`/`forceCn`/stem/led tokens; `byId` over all 11.
- `test/unit/switch_assets_test.dart:76-78` — `hasLength(8)` → `hasLength(22)`.
- `test/unit/click_sound_player_test.dart` — three `hasLength(8)` → `hasLength(22)`.
- `test/unit/app_colors_test.dart` — added the 7 new stem-token ARGB assertions.
- `test/widget/stats_panel_test.dart` — rewritten for the 2-value panel
  (total + rpm), asserts old keys are gone, reset cancel/confirm/barrier paths.
- `test/widget/smoke_widget_test.dart` — 2 stats + 11 chips + horizontal-scroll
  assertion; speedSilver chip reached via `ensureVisible` then selected.
- `test/widget/goldens/keycap_unpressed.png`, `keycap_pressed.png` — regenerated
  (deliberate, via `--update-goldens`) for the new cap visual.

Assets generated (auto-bundled; `assets/sounds/` is already a pubspec asset dir):
- `assets/sounds/{white,gray,clear,silentRed,silentBlack,speedSilver,darkGray}_{down,up}.wav`
  — 14 new WAVs (the original 8 are also re-emitted byte-identically by the run).

## Tests added / updated
- Unit catalog: every field of the 11-switch catalog, in order (AC1).
- Unit assets: exactly 22 valid mono/44100/16-bit WAVs > 1KB (AC2).
- Widget stats: exactly 2 values, increment, reset dialog paths (AC3, AC4).
- Widget keycap (existing, still passing): pressed visual state is reachable
  (scale < 1.0 while held) + one onPressDown/onPressUp per press (AC5).
- Golden: unpressed/pressed cap regenerated (AC5).
- Widget home/selector: 11 chips present, horizontal scroll, chip tap changes
  `selectedSwitchId` + keycap label (AC6).

## Verification evidence
- Format:    `evidence/dev/format.txt` — `Formatted 37 files (0 changed)`, EXIT_CODE=0
- Analyze:   `evidence/dev/analyze.txt` — `No issues found!`, EXIT_CODE=0
- Unit:      `evidence/dev/test-unit.txt` — `+132: All tests passed!`, EXIT_CODE=0
- Widget:    `evidence/dev/test-widget.txt` — `+36: All tests passed!` (non-golden), EXIT_CODE=0
- Golden:    `evidence/dev/test-golden.txt` — `+2: All tests passed!`, EXIT_CODE=0
             (regenerated: `evidence/dev/golden-update.txt`, EXIT_CODE=0)
- Full suite: `evidence/dev/test-all.txt` — `+171: All tests passed!`, EXIT_CODE=0
- Build:     `evidence/dev/build.txt` — `✓ Built build/app/outputs/flutter-apk/app-debug.apk`,
             EXIT_CODE=0; artifact `build/app/outputs/flutter-apk/app-debug.apk`, 208,830,514 bytes.
- Determinism (AC2): `evidence/dev/gen-sounds-determinism.txt` — sha256 of all 22
  WAVs identical across two runs (`DIFF_EXIT_CODE=0`), file count = 22.
- Runtime smoke (AC8, optional): `evidence/dev/smoke/` — installed on
  emulator-5554 (Android 15/API 35), launched (RESUMED, no crash); screenshots
  show the 2-value stats, sculpted keycap, and 11-chip horizontal selector;
  3 keycap taps drove total 1,512→1,515 (+3) and RPM 3; tapping the 진회축 chip
  changed the keycap label to "Dark Gray" and highlighted the chip; `logcat.txt`
  has no FATAL / no `E/flutter` / no app exception. `smoke-summary.txt`.

## AC → evidence map
- AC1 (11-switch catalog): `lib/domain/switch_type.dart` `SwitchCatalog.all`;
  `test/unit/switch_catalog_test.dart` → test-unit.txt (+132).
- AC2 (22 valid WAVs + determinism): `tools/gen_sounds.py`;
  `test/unit/switch_assets_test.dart` → test-unit.txt; gen-sounds-determinism.txt.
- AC3 (exactly 2 stats, increment): `lib/widgets/stats_panel.dart:60-90`;
  `test/widget/stats_panel_test.dart` + smoke screenshot-2/3.
- AC4 (reset → dialog → 0 persisted): `lib/widgets/stats_panel.dart:95-126`;
  `test/widget/stats_panel_test.dart` (confirm test).
- AC5 (keycap pronounced press + golden): `lib/widgets/keycap.dart:280-340`
  (travel/scale/skirt/glow); `test/widget/keycap_test.dart` (scale<1.0 while
  held) → test-widget.txt; goldens regenerated → test-golden.txt.
- AC6 (11 chips, horizontal scroll, tap selects): `lib/screens/home_screen.dart`
  `_SwitchSelector`/`_SwitchChip`; `test/widget/smoke_widget_test.dart` + smoke
  screenshot-4 (label → "Dark Gray").
- AC7 (analyze/format/test green): analyze.txt, format.txt, test-all.txt.
- AC8 (apk debug build + smoke): build.txt + `evidence/dev/smoke/`.

## Self-audit
- This is not a git repo, so `git diff --stat` is unavailable. The Changes list
  was reconciled against `find lib tools test -type f -newermt "2026-06-23 13:30"`,
  which returned exactly: `lib/domain/switch_type.dart`,
  `lib/screens/home_screen.dart`, `lib/theme/app_colors.dart`,
  `lib/widgets/keycap.dart`, `lib/widgets/stats_panel.dart`,
  `tools/gen_sounds.py`, `test/unit/{app_colors,click_sound_player,switch_assets,switch_catalog}_test.dart`,
  `test/widget/{smoke_widget,stats_panel}_test.dart` — plus the 14 new WAVs and
  the 2 regenerated golden PNGs (`assets/sounds/` + `test/widget/goldens/`). No
  other source files were modified.
- Every "passed/EXIT_CODE=0" claim above is backed by the named file under
  `evidence/dev/` containing the quoted line + a trailing `EXIT_CODE=` line.
- I generated all evidence this session; none was hand-edited.

## 11-switch confirmation (order + key fields)
blue(clicky/50) · brown(tactile/45) · red(linear/45) · black(linear/60) ·
white(clicky/55) · gray(tactile/80) · clear(tactile/65) · silentRed(linear/45) ·
silentBlack(linear/60) · speedSilver(linear/45) · darkGray(linear/80).
`defaultSwitch == all.first == blue`.

## Known limitations / UNVERIFIED
- UNVERIFIED (out of scope per spec): sound *realism/quality* is not evaluated —
  only that each switch has a distinct, valid, deterministically-generated clip.
- The golden surface (360px) renders the short "A" legend faintly against the
  bright dished center; on a real device the longer legends ("Brown", "Dark
  Gray") read clearly (smoke screenshot-2/4). The label widget is present and
  asserted by `keycap_test.dart` AC1 regardless.
- Coverage gate (pyramid layer 6) was not run; the task's Test plan does not
  require a coverage threshold for T012.
- Smoke interaction was driven via `adb input tap` (manual), not an
  `integration_test` harness; counter increment + switch change + label update +
  clean logcat were observed via screenshots.
