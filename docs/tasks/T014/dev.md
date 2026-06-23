# Dev report — T014

Status: implemented and self-checked; awaiting QA.

## Summary
Grew the switch lineup to 13 (added 황축 Yellow + 자석축 Magnetic), enriched
`SwitchType` with `recommendedFor` + `loudness` and repurposed `description` to
the 느낌 one-liner, and rebuilt the switch-selection menu so each row shows a
stem swatch, `nameKo (nameEn)`, a `kind · force · loudness-bar` meta line, the
느낌 description, and `추천: …`. Added matching yellow/magnetic sound params to
`gen_sounds.py` and regenerated 26 deterministic WAVs.

## Changes
(matches `git diff --stat` + new untracked files — see Self-audit)
- `lib/domain/switch_type.dart` — added `recommendedFor` + `loudness` fields
  (constructor + docs), repurposed `description` to 느낌; set 느낌 +
  `recommendedFor` + `loudness` on all 11 existing rows (id/kind/forceCn/
  stemColor/defaultLed/haptic unchanged); appended `yellow` and `magnetic`
  entries; added both to `SwitchCatalog.all` (now 13). `defaultSwitch`/`byId`
  untouched.
- `lib/theme/app_colors.dart:48` — added `switchYellow Color(0xFFFACC15)` and
  `switchMagnetic Color(0xFF2DD4BF)`.
- `lib/widgets/switch_menu.dart` — rebuilt `_SwitchRow` (heading
  `nameKo (nameEn)` + check; meta line `kind · NNcN` + new `_LoudnessBar`; 느낌
  description; `추천: recommendedFor`); added `_LoudnessBar` (5-segment meter
  with a `volume_up_rounded` icon); updated doc comments (13, not 11). Keys
  `switch-chip-<id>` and `sheetKey` preserved; selection still calls
  `notifier.selectSwitch(id)`.
- `tools/gen_sounds.py` — added `yellow` (fuller-body smooth linear) and
  `magnetic` (very smooth/quiet linear) param sets, added both to
  `SWITCH_ORDER`, updated header docstring (22 → 26).
- `test/unit/switch_catalog_test.dart` — `_expected` now 13 rows with `loudness`
  (as a `typedef _Row`); asserts length 13, last-two = yellow/magnetic, loudness
  ∈ [1,5], `recommendedFor` non-empty; value-semantics ctor gets the 2 new args.
- `test/unit/switch_assets_test.dart:76` — expect 26 clips (was 22).
- `test/unit/click_sound_player_test.dart` — expect 26 loaded assets (was 22),
  in 3 places + title.
- `test/unit/app_colors_test.dart` — new test for switchYellow/switchMagnetic
  ARGB.
- `test/widget/smoke_widget_test.dart` — `SwitchCatalog.all` length 13 (was 11);
  comment 11 → 13.
- `test/widget/switch_menu_test.dart` — NEW dedicated widget test (see below).
- `assets/sounds/yellow_down.wav`, `yellow_up.wav`, `magnetic_down.wav`,
  `magnetic_up.wav` — NEW generated WAVs (the other 22 regenerated
  byte-identical to the committed baseline — see Self-audit).

## Tests added / updated
- `test/widget/switch_menu_test.dart` (new) — AC4:
  - all 13 `switch-chip-<id>` rows present in the menu tree;
  - every row renders `nameKo (nameEn)`, `…cN`, the 느낌 description, and
    `추천: …`;
  - the magnetic row contains "무접점" and "e스포츠";
  - 13 loudness bars (one `volume_up_rounded` icon per row);
  - opening the menu + tapping `switch-chip-yellow` → `selectedSwitchId=='yellow'`,
    sheet closes, keycap `stemColor`/`label` update to yellow;
  - the selected row (seeded magnetic) shows exactly one check.
- `test/unit/switch_catalog_test.dart` — 13 rows, loudness, recommendedFor (AC1).
- `test/unit/switch_assets_test.dart` — 26 clips valid mono/44100/16-bit/>1KB (AC3).
- `test/unit/app_colors_test.dart` — 2 new stem tokens (AC2).
- `test/unit/click_sound_player_test.dart` — loads all 26 catalog assets.

## Verification evidence
- Format:    `evidence/dev/format-check.txt` — `dart format --set-exit-if-changed .`,
  "Formatted 42 files (0 changed)", EXIT_CODE=0. (AC5)
- Analyze:   `evidence/dev/analyze.txt` — "No issues found!", EXIT_CODE=0. (AC5)
- Unit:      `evidence/dev/test-unit.txt` — `+158: All tests passed!`, EXIT_CODE=0.
- Widget:    `evidence/dev/test-widget.txt` — `+48: All tests passed!`, EXIT_CODE=0.
- Full suite:`evidence/dev/test-all.txt` — `+207: All tests passed!`, EXIT_CODE=0
  (includes golden tests under test/widget). (AC5)
- Sounds:    26 WAVs in `assets/sounds/`. Determinism:
  `evidence/dev/gen-sounds-determinism.txt` — run1 vs run2 sha256 `diff`
  EXIT_CODE=0 (byte-identical), file count 26. `evidence/dev/sounds-git-status.txt`
  — 0 of the 22 pre-existing WAVs changed vs the committed baseline; only the 4
  new WAVs are untracked. (AC3)
- Build:     `evidence/dev/build.txt` — `flutter build apk --debug`,
  "✓ Built …/app-debug.apk", EXIT_CODE=0; artifact
  `build/app/outputs/flutter-apk/app-debug.apk`, 173938948 bytes. (AC6)
- Runtime smoke (emulator-5554, API 35): `evidence/dev/smoke/` —
  `home-1.png` (cliker home, 청축 keycap), `menu-1.png` (top of menu: 청축/갈축/
  적축/흑축 rows with swatch, name(En), kind·cN·loudness bar, 느낌, 추천; 청축
  selected with ring+check), `menu-bottom.png` (scrolled: 진회축/황축/자석축 —
  magnetic shows "무접점 홀이펙트·래피드 트리거" / "추천: e스포츠·정밀 제어"),
  `keycap-yellow.png` (after tapping 황축: menu closed, keycap label = 황축).
  `smoke/fatal-scan.txt` — 0 fatals in `smoke/logcat.txt`.

## AC mapping
- AC1 (13 rows, fields, 11 unchanged, default blue): `test-unit.txt`
  (switch_catalog_test) + `lib/domain/switch_type.dart`.
- AC2 (switchYellow/switchMagnetic exact hex): `test-unit.txt` (app_colors_test)
  + `lib/theme/app_colors.dart:48`.
- AC3 (26 WAVs valid + deterministic): `test-unit.txt` (switch_assets_test) +
  `gen-sounds-determinism.txt` + `sounds-git-status.txt`.
- AC4 (menu shows 13 rows with all info; magnetic 무접점/e스포츠; selecting
  yellow updates settings+keycap): `test-widget.txt` (switch_menu_test) +
  `smoke/menu-*.png`, `smoke/keycap-yellow.png`.
- AC5 (analyze clean, format 0, all tests green, no new deps): `analyze.txt`,
  `format-check.txt`, `test-all.txt`. No `pubspec.yaml` dependency changes
  (only catalog/menu/sounds/tests touched).
- AC6 (`flutter build apk --debug`): `build.txt`.

## Self-audit
Confirmed: every claim above is backed by a file under `evidence/dev/` with a
matching EXIT_CODE / result, generated this session. The `## Changes` list
reconciles with `git diff --stat` (9 tracked files) plus 5 untracked new files
(4 WAVs + switch_menu_test.dart), captured in `evidence/dev/git-diff-stat.txt`.

`git diff --stat`:
```
 lib/domain/switch_type.dart            | 103 +++++++++--
 lib/theme/app_colors.dart              |   2 +
 lib/widgets/switch_menu.dart           | 151 ++++++++++++---
 test/unit/app_colors_test.dart         |   5 +
 test/unit/click_sound_player_test.dart |   8 +-
 test/unit/switch_assets_test.dart      |   4 +-
 test/unit/switch_catalog_test.dart     | 327 +++++++++++++++++++--------------
 test/widget/smoke_widget_test.dart     |   4 +-
 tools/gen_sounds.py                    |  59 +++++-
 9 files changed, 471 insertions(+), 192 deletions(-)
```
Untracked (new): `assets/sounds/{yellow,magnetic}_{down,up}.wav`,
`test/widget/switch_menu_test.dart`.

## Known limitations / UNVERIFIED
- The smoke screenshots were captured by tap coordinates against the 320x640
  emulator; the widget test (`switch_menu_test.dart`) is the authoritative,
  reproducible check of the same behavior. Both agree.
- Sound *quality* of yellow/magnetic is out of scope (spec): only validity,
  count, and determinism are verified, not subjective realism.
- I did NOT git commit (per instructions); the new WAVs + new test are untracked
  and must be added/committed by the worker after QA.
