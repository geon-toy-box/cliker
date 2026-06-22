# Dev report — T009

## Summary
The app now presents as **클리커** with an on-brand launcher icon (dark keycap +
neon-RGB glow + cyan "C") instead of the default Flutter icon, and ships at
version 1.0.0+1. The 1024×1024 icon sources are rendered deterministically from
a pure-code Flutter widget (no external design assets) and the Android mipmap /
adaptive-icon resources are generated from them by `flutter_launcher_icons`.
Implemented and self-checked on emulator-5554; awaiting QA.

## Changes
Modified (tracked) — matches `git diff --stat`, see evidence/dev/git-diff-stat.txt:
- `android/app/src/main/AndroidManifest.xml:3` — `android:label` "cliker" → "클리커" (AC1). app id / applicationId / Kotlin package untouched.
- `android/app/src/main/res/mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher.png` — legacy launcher icons regenerated from the new source (Bin 442→4638 … 1443→30145 bytes) (AC2).
- `dart_test.yaml:6` — registered the `icon-gen` test tag.
- `pubspec.yaml:42,50` — added `flutter_launcher_icons: ^0.14.4` dev_dependency + the `flutter_launcher_icons:` config block (Android adaptive + legacy). version line confirmed `1.0.0+1` (AC4).
- `pubspec.lock` — resolved the new dev_dependency tree (flutter_launcher_icons + transitive image/archive/xml/etc).

New (untracked):
- `lib/icon/app_icon.dart` — `AppIcon` / `AppIcon.foreground` widget: pure-code, deterministic keycap-with-neon-glow painter reusing `AppColors` (no blur filters; gradient-based glow so it rasterizes fast & identically headless).
- `assets/icon/icon.png` — committed 1024×1024 full legacy icon source (AC3).
- `assets/icon/icon_foreground.png` — committed 1024×1024 adaptive foreground source (AC3).
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` — adaptive-icon XML (background `@color/ic_launcher_background`, inset foreground) (AC2).
- `android/app/src/main/res/values/colors.xml` — `ic_launcher_background = #0A0A0F` (= `AppColors.bg`).
- `android/app/src/main/res/drawable-{m,h,xh,xxh,xxxh}dpi/ic_launcher_foreground.png` — adaptive foreground bitmaps (AC2).
- `test/tools/generate_app_icon_test.dart` — `icon-gen`-tagged generator: renders `AppIcon` via `RepaintBoundary.toImage` at 1024², asserts PNG/1024², writes the two sources.
- `test/unit/app_icon_assets_test.dart` — unit guard: the two committed PNGs exist, are valid 1024×1024 PNGs, are non-trivial, and differ from every stock mipmap.

## Tests added
- `test/tools/generate_app_icon_test.dart` — renders + writes the 1024×1024 icon sources; asserts PNG magic + 1024×1024 dims for both layers.
- `test/unit/app_icon_assets_test.dart` — asserts committed sources exist, are valid 1024×1024 PNGs >1KB, and are not byte-identical to any stock mipmap.

## Verification evidence
- Format:    evidence/dev/format.txt — EXIT_CODE=0 (no reformatting needed).
- Analyze:   evidence/dev/analyze.txt — "No issues found! (ran in 1.2s)" EXIT_CODE=0.
- Unit:      evidence/dev/test-unit.txt — "+89: All tests passed!" EXIT_CODE=0 (incl. app_icon_assets_test.dart).
- Widget:    evidence/dev/test-widget.txt — "+37: All tests passed!" EXIT_CODE=0.
- Golden:    evidence/dev/test-golden.txt — "+2: All tests passed!" EXIT_CODE=0 (keycap goldens, no visual regression).
- Full suite: evidence/dev/test-all.txt — "+127: All tests passed!" EXIT_CODE=0 (`flutter test`, golden-tagged excluded by default; incl. the icon-gen generator).
- Icon gen (AC3): evidence/dev/icon-gen.txt — "+1: All tests passed!" EXIT_CODE=0.
- Icon determinism (AC3): evidence/dev/icon-gen-rerun.txt — re-run EXIT_CODE=0; "icon.png IDENTICAL", "icon_foreground.png IDENTICAL" (byte-for-byte across runs). Stable hashes:
  - icon.png            sha256 64aafd63d02a9ec0c08dc2d1f7e7d3f85fc272e02f55515840b2afb47dc892ee
  - icon_foreground.png sha256 6ebe8925652bb9aa956fac984ac2f063fe04035c4e740b8f3a1e9b95f26b049d
- Launcher-icons gen: evidence/dev/launcher-icons-gen.txt — "✓ Successfully generated launcher icons" EXIT_CODE=0 (`dart run flutter_launcher_icons`).
- Icon resources (AC2): evidence/dev/icon-resources.txt — new mipmap hashes differ from recorded baseline defaults; adaptive xml + 5 foreground bitmaps listed present.
- Build (AC5):   evidence/dev/build.txt — "✓ Built build/app/outputs/flutter-apk/app-debug.apk" EXIT_CODE=0; artifact app-debug.apk = 189300379 bytes.
- APK badging (AC1/AC2/AC4): evidence/dev/apk-badging.txt — `package name='com.secondsyndrome.cliker' versionCode='1' versionName='1.0.0'`; `application: label='클리커' icon='res/mipmap-anydpi-v26/ic_launcher.xml'`.
- Install:    evidence/dev/install.txt — "Success" EXIT_CODE=0 (`adb -s emulator-5554 install -r`).
- Runtime smoke (AC1/AC2/AC5):
  - evidence/dev/smoke/app-running.png — app launches; HomeScreen renders (stats panel + neon "Blue" keycap + switch selector).
  - evidence/dev/smoke/app-after-clicks.png — core loop works: 5 taps registered (누적/세션/CPM/최고 CPM = 5), ripple visible.
  - evidence/dev/smoke/app-info.png — Android App-info screen shows the new cliker icon directly above the name **클리커**.
  - evidence/dev/smoke/launcher-allapps.png — all-apps drawer shows the cliker adaptive icon + label **클리커** together (other Flutter sample apps still show the default icon, by contrast).
  - evidence/dev/smoke/launcher-drawer.png — home/dock shows the round-masked neon adaptive icon.
  - evidence/dev/logcat.txt — no FATAL/AndroidRuntime/E/flutter lines; only normal audio-focus + EGL frame-timing (~60fps) logs.
- Integration (integration_test/): N/A for this task — icon/name/version are resource & manifest changes with no new Dart UI flow; runtime smoke above covers the on-device surface. Existing integration_test suite was not modified.

## Self-audit
Confirmed: every claim above is backed by a file under evidence/dev/ with a
matching EXIT_CODE/result line (or a screenshot), all produced this session on
emulator-5554. The committed icon PNGs reproduce byte-identically from the
source (two clean runs + a third during the full suite, all matching hashes).
git diff --stat (modified tracked files) — pasted verbatim from
evidence/dev/git-diff-stat.txt:

```
 android/app/src/main/AndroidManifest.xml           |   2 +-
 .../app/src/main/res/mipmap-hdpi/ic_launcher.png   | Bin 544 -> 8529 bytes
 .../app/src/main/res/mipmap-mdpi/ic_launcher.png   | Bin 442 -> 4638 bytes
 .../app/src/main/res/mipmap-xhdpi/ic_launcher.png  | Bin 721 -> 11781 bytes
 .../app/src/main/res/mipmap-xxhdpi/ic_launcher.png | Bin 1031 -> 20780 bytes
 .../src/main/res/mipmap-xxxhdpi/ic_launcher.png    | Bin 1443 -> 30145 bytes
 dart_test.yaml                                     |   2 +
 pubspec.lock                                       |  72 +++++++++++++++++++++
 pubspec.yaml                                       |  15 +++++
 9 files changed, 90 insertions(+), 1 deletion(-)
```

New/untracked files (not shown by diff --stat): android/app/src/main/res/drawable-{m,h,xh,xxh,xxxh}dpi/ic_launcher_foreground.png,
android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml, android/app/src/main/res/values/colors.xml,
assets/icon/icon.png, assets/icon/icon_foreground.png, lib/icon/app_icon.dart,
test/tools/generate_app_icon_test.dart, test/unit/app_icon_assets_test.dart.
The Changes list above equals modified + new = the full git status.

## AC → evidence map
- AC1 (name 클리커): AndroidManifest.xml:3 + apk-badging.txt (`label='클리커'`) + smoke/app-info.png + smoke/launcher-allapps.png.
- AC2 (icon replaced, mipmaps + adaptive xml, bytes differ): icon-resources.txt + git-diff-stat.txt (Bin size growth) + mipmap-anydpi-v26/ic_launcher.xml + smoke/app-info.png + smoke/launcher-allapps.png.
- AC3 (1024² source committed, reproducible): assets/icon/*.png + icon-gen.txt + icon-gen-rerun.txt (IDENTICAL hashes) + test/tools/generate_app_icon_test.dart + test/unit/app_icon_assets_test.dart.
- AC4 (version 1.0.0+1): pubspec.yaml:19 + apk-badging.txt (`versionCode='1' versionName='1.0.0'`).
- AC5 (debug APK builds; runtime smoke icon+name): build.txt + install.txt + smoke/*.png + logcat.txt.
- AC6 (analyze clean / format 0 / tests green incl. icon render, no regression): analyze.txt + format.txt + test-unit.txt + test-widget.txt + test-golden.txt + test-all.txt + icon-gen.txt.

## Known limitations / UNVERIFIED
- `UNVERIFIED:` icon visual quality is a judgement call, not mechanically asserted. The generator/unit tests verify the PNGs are valid 1024×1024 and on-brand-by-construction (reuse AppColors), and the on-device screenshots show the masked adaptive icon, but there is no golden pixel-lock on the icon source itself (only a determinism/round-trip check via hashes). If QA wants a hard pixel guard, a golden could be added.
- The adaptive foreground (`AppIcon.foreground`) bakes a soft dark radial backdrop into the transparent canvas; layered over `#0A0A0F` it reads as one dark surface (see smoke/app-info.png), which is the intended look. Noted in case QA expects a fully transparent field outside the keycap.
- No `git commit` was run (per instructions). DoD's commit step is left to the worker after QA VERIFIED.
