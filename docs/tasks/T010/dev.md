# Dev report — T010

## Summary
Generated an upload keystore (gitignored, never committed), wired release
signing in `android/app/build.gradle.kts` from `android/key.properties`, enabled
R8 code shrinking + resource shrinking with a `proguard-rules.pro` keep set,
audited the release manifest permissions, and built a signed AAB. The R8 release
variant was installed and smoke-tested on emulator-5554: it launches, the core
tap→counter loop works, audioplayers is alive (not stripped), and there are no
crashes.

## Changes
- `.gitignore:54-60` — added an explicit Android-signing ignore block
  (`android/key.properties`, `android/upload-keystore.jks`, `**/*.jks`,
  `**/*.keystore`) so secrets cannot be staged. (Belt-and-suspenders; the
  existing `android/.gitignore:12-14` already covered them.)
- `android/app/build.gradle.kts:1-20` — import `Properties`/`FileInputStream`
  and load `key.properties` at the top (graceful `hasReleaseSigning` flag when
  the file is absent, for CI/fresh checkout).
- `android/app/build.gradle.kts:47-77` — `signingConfigs.create("release")`
  from the loaded props; `buildTypes.release` uses the release signing config
  (debug fallback only when key.properties is absent) and enables
  `isMinifyEnabled=true`, `isShrinkResources=true`, with `proguardFiles(...)`.
- `android/app/proguard-rules.pro` (new) — R8 keep rules for Flutter embedding
  and audioplayers (ExoPlayer/Media3) so reflective classes survive shrinking.

`git diff --stat` (tracked/stage-able source only — `build/` and
`docs/tasks/**/evidence/` are gitignored):
```
 .gitignore                   |  7 +++++++
 android/app/build.gradle.kts | 44 +++++++++++++++++++++++++++++++++++++++++---
 2 files changed, 48 insertions(+), 3 deletions(-)
```
Plus untracked new source file `?? android/app/proguard-rules.pro`.
The secrets `android/key.properties` and `android/upload-keystore.jks` exist on
disk but are correctly **NOT** tracked (verified — see AC1).

## Tests added
None. Per the task's own test plan, Unit/Widget/Golden/Integration are N/A for
this task (build/signing/permission config only — no app logic changed). The
existing suite (127 tests) was run unchanged as a regression gate, and the R8
release variant was smoke-tested on a device (the substantive verification here).

## Verification evidence — AC mapping
- **AC1 (secrets gitignored, untracked):**
  - `evidence/dev/gitignore-check.txt` — `git check-ignore` echoes both paths
    (ignored via `android/.gitignore:12` and `:14`); `git ls-files | grep` →
    "(none tracked — GOOD)"; `git add` without `-f` refused both
    ("git add … exit=1", no secret staged).
  - `evidence/dev/final-git-check.txt` — re-checked AFTER building: still no
    secret tracked; `git status --short` shows only `.gitignore`,
    `build.gradle.kts`, `proguard-rules.pro`.
  - `evidence/dev/keytool.txt` — keystore generation EXIT_CODE=0.
- **AC2 (release signing config from key.properties, not debug):**
  - `android/app/build.gradle.kts:47-77` (quoted in Changes). Proven at runtime
    by AC3 — the release artifact is signed by the upload alias, not the debug
    key.
- **AC3 (signed AAB produced + signer verified = upload key):**
  - `evidence/dev/build-aab.txt` — `flutter build appbundle --release`
    EXIT_CODE=0, "Built …/app-release.aab (41.5MB)".
  - `evidence/dev/aab-artifact.txt` — `ls -l` → 41,491,782 bytes on disk.
  - `evidence/dev/aab-signature-verify.txt` — `jarsigner -verify` prints
    "jar verified."; unique signer DN = `CN=cliker, O=secondsyndrome, C=KR`.
    (jarsigner's non-zero exit is from benign warnings — self-signed cert / no
    timestamp / Jar inconsistencies, all normal for a v1-signed AAB that Play
    re-signs; the verdict line is "jar verified.")
  - `evidence/dev/apk-signature-verify.txt` — DEFINITIVE: `apksigner verify
    --print-certs` EXIT_CODE=0, signer DN `CN=cliker, O=secondsyndrome, C=KR`,
    cert SHA-256 `65aa2ca0…49495e` which **exactly matches** the upload
    keystore fingerprint `65:AA:2C:A0:…:49:5E` (`evidence/dev/keystore-list.txt`).
- **AC4 (permission audit — no unnecessary permissions):**
  - `evidence/dev/permissions.txt` — `aapt2 dump badging` on the release APK +
    cross-check of the merged release manifest
    (`build/app/intermediates/merged_manifest/release/.../AndroidManifest.xml`).
    The release manifest declares exactly ONE permission:
    `com.secondsyndrome.cliker.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`
    (auto-generated, signature-level, app-private — added by androidx.core to
    guard non-exported dynamic BroadcastReceivers on API 34+; not user-facing,
    no consent). **No `android.permission.INTERNET`** and no network/dangerous
    permission ("INTERNET permission ABSENT in release — GOOD"). Haptics
    (HapticFeedback platform channel) and audioplayers local playback require no
    Android permission. INTERNET is present only in the debug/profile manifests
    (`android/app/src/debug/AndroidManifest.xml:6`,
    `…/profile/AndroidManifest.xml:6`) for Flutter hot-reload and is not merged
    into release.
- **AC5 (R8 release variant runs on device — core loop, no crash):**
  - `evidence/dev/release-smoke-install.txt` — `adb install` EXIT_CODE=0;
    `am start` EXIT_CODE=0.
  - `evidence/dev/release-smoke-runtime.txt` — PID=12522,
    `topResumedActivity=…/.MainActivity`.
  - `evidence/dev/smoke/screenshot-1-launch.png` — app rendered (stats panel,
    "Blue" keycap with glow, four switch chips, settings gear) under R8.
  - `evidence/dev/smoke/screenshot-2-after-taps.png` — after 5 keycap taps:
    누적=5, 세션=5, CPM=5, 최고 CPM=5 → core loop works under obfuscation.
  - `evidence/dev/release-smoke-logscan.txt` — no FATAL EXCEPTION, no
    ClassNotFound/NoSuchMethod/NoClassDefFound (R8 did not over-strip);
    audioplayers (`xyz.luan.audioplayers.player`) successfully calls
    `requestAudioFocus()` on tap → sound backend not stripped. Only "E" line is
    the benign "Not starting debugger … jdwp agent" (expected for a
    non-debuggable release build).
- **AC6 (analyze/format/test):**
  - Format:  `evidence/dev/format.txt` — "Formatted 37 files (0 changed)", EXIT_CODE=0.
  - Analyze: `evidence/dev/analyze.txt` — "No issues found!", EXIT_CODE=0.
  - Test:    `evidence/dev/test.txt` — "All tests passed!" (+127), EXIT_CODE=0.

## Test pyramid layers
- Format / Analyze: PASS (evidence above).
- Unit / Widget / Golden / Integration: N/A per task test plan (no app-logic
  change). Existing 127-test suite re-run as regression gate — PASS.
- Build: PASS — signed AAB (41.5MB) + signed APK (46.5MB) produced.
- Runtime smoke: PASS — R8 release APK installed & exercised on emulator-5554.

## Self-audit
Confirmed: every claim above is backed by a file under
`docs/tasks/T010/evidence/dev/` with a matching EXIT_CODE / result, read this
session. `git diff --stat` matches the Changes list (`.gitignore`,
`android/app/build.gradle.kts` tracked-modified; `android/app/proguard-rules.pro`
untracked-new). The two secret files are present on disk and verified NOT
tracked/stage-able. Diff stat pasted in Changes above.

Status: implemented and self-checked; awaiting QA. (No DONE/VERIFIED claimed.)

## R8 keep rules added (caveat for QA)
`android/app/proguard-rules.pro` keeps `io.flutter.**` and
`xyz.luan.audioplayers.**` / `androidx.media3.**` / `com.google.android.exoplayer2.**`.
These were precautionary; the smoke run confirms audioplayers initializes and
requests audio focus under R8, so no missing-class crash was observed.

## Known limitations / UNVERIFIED
- UNVERIFIED: I did not verify per-tap audible sound (emulator audio not
  inspected) — only that the audioplayers backend ran and requested audio focus
  without crashing. The visual counter increment is verified.
- The keystore listing evidence (`keystore-list.txt`) has an empty EXIT_CODE
  line (PIPESTATUS captured through a grep pipe); the authoritative cert proof
  is `apk-signature-verify.txt` (apksigner EXIT_CODE=0, SHA-256 match).
- AAB-internal APK verification was done via the equivalent release APK
  (`apksigner`, same signing config), not via bundletool build-apks (bundletool
  not installed). The APK and AAB share `signingConfigs.release`, and jarsigner
  independently confirmed the AAB signer DN.
- Out of scope per task: actual Play Console upload (user performs this with
  their own account). The keystore passwords must be backed up by the user (see
  the message to the worker) — they are NOT stored in any git-tracked file.
