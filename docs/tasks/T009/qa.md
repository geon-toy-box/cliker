# QA verdict — T009

## Verdict: PASS

App identity (name 클리커 + on-brand neon-keycap launcher icon + version 1.0.0+1)
independently verified on emulator-5554. Every applicable test-pyramid layer
passed with QA's own evidence, the dev.md document audit is fully BACKED, and all
six acceptance criteria are met. No source edited, no commit made by QA.

## Independent test results
- Format:    evidence/qa/format.txt — "Formatted 37 files (0 changed)" EXIT_CODE=0
- Analyze:   evidence/qa/analyze.txt — "No issues found! (ran in 1.6s)" EXIT_CODE=0
- Unit:      evidence/qa/test-unit.txt — +89 passed, 0 failed, EXIT_CODE=0
- Widget:    evidence/qa/test-widget.txt — +37 passed, 0 failed, EXIT_CODE=0
- Golden:    evidence/qa/test-golden.txt — +2 passed, 0 failed, EXIT_CODE=0 (keycap goldens)
- Icon-gen:  evidence/qa/icon-gen-run1.txt + icon-gen-run2.txt — +1 each, EXIT_CODE=0 (×2 reruns)
- Full suite: evidence/qa/test-all.txt — +127 "All tests passed!" EXIT_CODE=0 (no regression)
- Coverage:  not required by task.md test plan (Unit marked N/A there; icon is resource/config).
             Not run as a gate — no coverage threshold defined for this task.
- Integration: N/A per task.md ("아이콘/이름/버전은 리소스 & 매니페스트 변경"); runtime smoke covers the device surface.
- Build:     evidence/qa/build.txt — "✓ Built app-debug.apk" EXIT_CODE=0;
             artifact at build/app/outputs/flutter-apk/app-debug.apk = 189300379 bytes (evidence/qa/build-artifact.txt)
- Smoke:     evidence/qa/smoke/launcher-allapps.png + app-home.png + app-after-taps.png + evidence/qa/logcat.txt —
             0 FATAL/AndroidRuntime/E/flutter; app launches and core loop works.

## Document audit
evidence/qa/doc-audit.txt — 19 claims audited, ALL BACKED. 0 UNBACKED, 0 CONTRADICTED.
git diff --stat reproduced verbatim (evidence/qa/git-diff-stat.txt) matching dev.md's pasted block.
One immaterial nit: dev cited `dart_test.yaml:6` for the icon-gen tag; actual added lines are 7-8
(content correct — not a defect). Document PASSES audit.

## Spec conformance (acceptance criteria)
- AC1 (install/launcher name = 클리커) → MET. AndroidManifest.xml:3 `android:label="클리커"`;
  aapt2 dump badging (evidence/qa/apk-badging.txt) `application-label:'클리커'`;
  evidence/qa/smoke/launcher-allapps.png shows the app labeled **클리커** in the all-apps drawer.
- AC2 (launcher icon replaced, not stock Flutter; mipmaps + adaptive xml; bytes differ) → MET.
  5 legacy mipmaps present; all differ byte-for-byte (sha256) from git HEAD stock defaults
  (evidence/qa/mipmap-vs-stock.txt, e.g. mdpi 442B→4638B, dims preserved 48×48);
  android/.../mipmap-anydpi-v26/ic_launcher.xml adaptive icon exists (verified content) and is
  packaged in the APK (badging icon = res/mipmap-anydpi-v26/ic_launcher.xml; unzip -l in apk inspection);
  5 drawable-*/ic_launcher_foreground.png present + packaged; colors.xml ic_launcher_background=#0A0A0F.
  Visually distinct from the two stock-icon "devlingo" apps in launcher-allapps.png.
- AC3 (1024² source committed + reproducible generator; cmd/hash in evidence) → MET.
  assets/icon/icon.png + icon_foreground.png exist, both 1024×1024 PNG (sips). Two independent
  reruns of the icon-gen test produced byte-identical sha256
  (icon.png 64aafd63…92ee, icon_foreground.png 6ebe8925…b049d) matching the committed sources —
  evidence/qa/icon-sha-committed.txt vs icon-sha-run1.txt vs icon-sha-run2.txt. Pure code: app_icon.dart
  uses AppColors only, zero external image/asset refs.
- AC4 (version 1.0.0+1) → MET. pubspec.yaml:19 `version: 1.0.0+1`;
  aapt2 badging `versionCode='1' versionName='1.0.0'`.
- AC5 (debug APK builds with new icon/name; runtime smoke confirms) → MET.
  Independent `flutter build apk --debug` EXIT_CODE=0, artifact on disk (189300379 B). Installed on
  emulator-5554 (Success), launched: app-home.png renders HomeScreen, app-after-taps.png shows the
  core loop (5 taps → 누적/세션/CPM/최고 CPM all = 5), logcat clean. Icon+name confirmed in
  launcher-allapps.png.
- AC6 (analyze "No issues found!" / format 0 / tests green incl. icon render, no regression) → MET.
  analyze.txt, format.txt, test-unit.txt, test-widget.txt, test-golden.txt, icon-gen runs, test-all.txt
  (+127) — all green, EXIT_CODE=0.

## Scope conformance (out-of-scope guards)
- applicationId / namespace / Kotlin package = `com.secondsyndrome.cliker` UNCHANGED — not present in
  `git diff` (verified). build.gradle.kts:9/24 + MainActivity.kt:1 read the unchanged id.
- `flutter_launcher_icons` is a DEV dependency only (pubspec.lock `dependency: "direct dev"`); the
  runtime `dependencies:` block is unchanged in the diff — no new runtime dependency.

## Findings
None.

VERIFIED
