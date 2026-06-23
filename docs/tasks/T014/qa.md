# QA verdict — T014

All results below were produced this session by QA into `docs/tasks/T014/evidence/qa/`
on `emulator-5554` (Android 15 / API 35), independent of the developer's evidence.

## Verdict: PASS

## Independent test results
- Format:    evidence/qa/format.txt — "Formatted 42 files (0 changed)", EXIT_CODE=0
- Analyze:   evidence/qa/analyze.txt — "No issues found!", EXIT_CODE=0
- Unit:      evidence/qa/test-unit.txt — +158 passed, 0 failed, EXIT_CODE=0
- Widget:    evidence/qa/test-widget.txt — +48 passed, 0 failed, EXIT_CODE=0 (incl. new switch_menu_test 6 cases)
- Golden:    N/A per task.md test plan ("키캡 변경 없음; 메뉴 골든은 선택"). Golden tests
             under test/widget ran inside the full suite below — green.
- Full suite: evidence/qa/test-all.txt — +207 passed, 0 failed, EXIT_CODE=0
- Coverage:  N/A — no coverage threshold configured (analysis_options.yaml / dart_test.yaml /
             pubspec.yaml) and none required by task.md test plan; not enforced for this task.
- Integration: N/A — task ships no integration_test for this feature; the AC4 flow is covered
             by the widget test (yellow selection → keycap update) and the runtime smoke below.
- Build:     evidence/qa/build.txt — "✓ Built build/app/outputs/flutter-apk/app-debug.apk",
             EXIT_CODE=0; artifact evidence/qa/build-artifact.txt — 173938948 bytes on disk.
- Smoke:     evidence/qa/smoke/ — screenshot-1-home.png (renders, no crash),
             screenshot-2-menu-top.png (축 선택; 청축/갈축/적축 rows: dot + name(En) +
             kind·cN + loudness bar + 느낌 + 추천; blue selected w/ check),
             screenshot-3-menu-bottom.png + screenshot-4-menu-magnetic.png (황축/자석축;
             magnetic shows "무접점 홀이펙트·래피드 트리거" / "추천: e스포츠·정밀 제어"),
             screenshot-5-keycap-yellow.png (tapped 황축 → menu closed, keycap label = 황축).
             logcat.txt + fatal-scan.txt — SCAN_EXIT=1 (0 fatals), app "Fully drawn".

## Document audit
evidence/qa/doc-audit.txt — 11 change-claims + 8 result-claims + omission/diff-stat check,
ALL BACKED. 0 UNBACKED, 0 CONTRADICTED. (Two immaterial line-number drifts noted: C2 cites
app_colors.dart:48 vs actual :49-50; C6 cites :76 vs :76-77 — symbols present and correct.)
git diff --stat reproduced identically (9 files, 471 ins / 192 del); untracked = exactly the
4 new WAVs + switch_menu_test.dart; dev did not commit (consistent with instructions).

## Spec conformance
- AC1 — SwitchCatalog.all is the 13 in spec order, fields correct, 11 unchanged, default=blue → MET
    - lib/domain/switch_type.dart:326-340 lists 13 (11 existing + yellow + magnetic) in order.
    - git diff (evidence/qa/git-diff-stat.txt + read): existing 11 changed only `description`;
      id/kind/forceCn/stemColor/defaultLed/hapticStrength/names/assets UNCHANGED.
    - Every row has non-empty recommendedFor, loudness∈[1,5], description (느낌) — asserted by
      switch_catalog_test (evidence/qa/test-unit.txt +158, includes row-for-row field check).
    - yellow: linear/50cN/loud2/stem switchYellow/led neonYellow/haptic0.5; magnetic: linear/
      40cN/loud1/stem switchMagnetic/led neonCyan/haptic0.45 — match spec (switch_type.dart:290-323).
    - defaultSwitch == all.first == blue, byId intact (switch_type.dart:343-353; test asserts).
- AC2 — switchYellow #FFFACC15 + switchMagnetic #FF2DD4BF in AppColors → MET
    - app_colors.dart:49-50 exact hex; app_colors_test asserts toARGB32 (evidence/qa/test-unit.txt).
- AC3 — 26 WAVs valid (mono/44100/16-bit/>1KB) + deterministic regeneration → MET
    - evidence/qa/wav-ondisk.txt: 26 WAVs, all >1KB; switch_assets_test parses real WAV headers
      (PCM/mono/44100/16-bit) — green in test-unit.txt.
    - evidence/qa/gen-sounds-determinism.txt: ran gen_sounds.py TWICE into isolated temp dirs —
      run1 == run2 (diff -rq exit 0, byte-identical) AND run1 == committed on-disk tree
      (diff -rq exit 0); sha256 of all 26 matches the on-disk shasums.
- AC4 — menu shows 13 rows with kind·force·loudness·느낌·추천; magnetic 무접점/e스포츠;
    selecting yellow sets selectedSwitchId=='yellow' + updates keycap → MET
    - switch_menu_test.dart asserts (not no-ops): 13 switch-chip-<id> present; each row's heading,
      ${forceCn}cN, description, "추천: ${recommendedFor}"; magnetic textContaining '무접점' & 'e스포츠';
      findsNWidgets(13) volume_up_rounded; full-app tap switch-chip-yellow → selectedSwitchId=='yellow',
      sheet findsNothing, keycap stemColor+label == yellow; seeded-magnetic shows exactly one check —
      all green (evidence/qa/test-widget.txt +48).
    - Runtime confirmed: evidence/qa/smoke/screenshot-2/4/5 (menu render, magnetic 무접점/e스포츠,
      tap 황축 → keycap = 황축).
- AC5 — analyze clean, format 0, all tests green, no new deps → MET
    - format.txt/analyze.txt/test-all.txt above; pubspec.yaml diff empty, pubspec.lock unchanged
      (evidence/qa/git-diff-stat.txt) → zero new dependencies.
- AC6 — flutter build apk --debug succeeds → MET
    - evidence/qa/build.txt EXIT_CODE=0 + build-artifact.txt (173938948-byte APK on disk).
- Scope (keycap/RGB-wheel/stats/audio mediaPlayer unchanged from T013) → MET
    - Only 3 lib files modified (switch_type, app_colors, switch_menu); no audio source
      (click_sound_player.dart), keycap, rgb_wheel, stats, or home_screen source changed
      (evidence/qa/git-diff-stat.txt + git diff --name-only).

## Findings
None. Every applicable layer passed on QA-generated evidence, the document audit is fully
BACKED, and every acceptance criterion is met.

## Notes
- Coverage and integration layers are N/A for this task (no configured threshold; no
  integration_test for the feature). The AC4 behavior is independently verified by both the
  widget test and the on-device runtime smoke, so this gap does not weaken the verdict.
- Dev has not committed (per instructions). The worker must `git add` the 4 new WAVs
  (assets/sounds/{yellow,magnetic}_{down,up}.wav) and test/widget/switch_menu_test.dart before
  recording DONE with the commit hash.

VERIFIED
