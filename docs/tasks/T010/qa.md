# QA verdict — T010

Release build: signing config + AAB + permissions audit. All evidence below was
generated independently by QA this session under `docs/tasks/T010/evidence/qa/`.
Emulator: `emulator-5554` (Android 15 / API 35). Flutter 3.41.7 stable.

## Verdict: PASS

## Independent test results
- Format:    evidence/qa/format.txt — "Formatted 37 files (0 changed)", EXIT_CODE=0
- Analyze:   evidence/qa/analyze.txt — "No issues found!", EXIT_CODE=0
- Unit/Widget/Golden/Integration: N/A per task test plan (build/signing/permission
  config only, no app-logic change). Existing suite re-run as regression gate.
- Test (regression): evidence/qa/test.txt — "+127: All tests passed!", EXIT_CODE=0
- Coverage:  N/A for this task (no logic added; not in task test plan)
- Build (AAB): evidence/qa/build-aab.txt — EXIT_CODE=0, "Built …/app-release.aab (41.5MB)";
  artifact evidence/qa/aab-artifact.txt — `build/app/outputs/bundle/release/app-release.aab`, 41,491,782 bytes
- Build (APK): evidence/qa/build-apk.txt — EXIT_CODE=0; artifact
  `build/app/outputs/flutter-apk/app-release.apk`, 46,542,337 bytes
- Smoke:     evidence/qa/smoke/screenshot-1-launch.png + screenshot-2-after-taps.png
  + evidence/qa/ac5-logcat.txt / ac5-logscan.txt — no fatal, core loop works under R8

## Document audit
evidence/qa/doc-audit.txt — 25 claims audited, **0 UNBACKED, 0 CONTRADICTED**
(every dev.md claim BACKED). One benign QA-found omission: dev.md did not mention
that the merged release manifest carries `android:permission="android.permission.DUMP"`
as a *guard attribute* on an auto-injected androidx ProfileInstaller component — this
is the app *protecting* that component, NOT a permission the app requests, and does
not change the AC4 outcome (evidence/qa/ac4-dump-investigation.txt,
ac4-dump-component.txt).

## Spec conformance

- **AC1** (key.properties + keystore exist, gitignored, untracked; no secret in repo)
  → **met**.
  - evidence/qa/ac1-secret-tracking.txt: `git ls-files | grep` for secrets → empty
    (GREP_EXIT=1); `git check-ignore -v` lists both via android/.gitignore:12 and :14
    (EXIT=0); `git status --porcelain` does not list either secret; `git add` without
    `-f` refused both (exit=1, not staged).
  - evidence/qa/ac1-password-leak-scan.txt: the storePassword string from
    key.properties is **absent from every git-tracked file** (`git grep` exit=1) and
    a whole-tree `find+grep` finds it in **only** `android/key.properties`, which is
    confirmed IGNORED. (Password string deliberately not reproduced in this doc or its
    evidence output — see key.properties.)
  - evidence/qa/ac1-final-recheck.txt: re-verified AFTER all builds — still untracked,
    still ignored, no leak introduced by the build.
  - Both files present on disk: `android/key.properties` (170 B),
    `android/upload-keystore.jks` (2632 B).

- **AC2** (release buildType uses key.properties-based signingConfig, not debug)
  → **met**.
  - Source: `android/app/build.gradle.kts:47-77` (evidence/qa/devmd-citation-check.txt)
    — `signingConfigs.create("release")` reads keyAlias/keyPassword/storeFile/
    storePassword from the loaded properties; `buildTypes.release.signingConfig =
    signingConfigs.getByName("release")` when key.properties exists (debug only as a
    fallback when the file is absent).
  - Runtime proof: evidence/qa/ac3-fingerprint-crosscheck.txt — the release artifact's
    signer cert SHA-256 equals the **upload** keystore and differs from the Android
    **debug** key. The release is genuinely upload-signed, not debug-signed.

- **AC3** (signed AAB produced; signer = upload key) → **met**.
  - AAB built (EXIT_CODE=0) and on disk at 41,491,782 B (build-aab.txt, aab-artifact.txt).
  - `jarsigner -verify` on the AAB: "jar verified.", signer DN
    `CN=cliker, O=geontoybox, C=KR` (evidence/qa/aab-signature-jarsigner.txt).
  - DEFINITIVE: `apksigner verify --print-certs` on the release APK (EXIT_CODE=0, v2
    scheme) → DN `CN=cliker, O=geontoybox, C=KR`, cert SHA-256
    `65aa2ca0…49495e` (evidence/qa/apk-signature-apksigner.txt), which **exactly
    matches** the upload keystore fingerprint in evidence/qa/keystore-fingerprint.txt
    and is **different** from the Android debug key (evidence/qa/ac3-fingerprint-crosscheck.txt).

- **AC4** (permission audit; no unnecessary/dangerous permissions) → **met**.
  - `aapt dump permissions` on the release APK: the sole requested permission is the
    auto-generated, signature-level, app-private
    `com.geontoybox.cliker.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`;
    **`android.permission.INTERNET` ABSENT**; no network/dangerous permission
    (evidence/qa/ac4-permissions-apk.txt).
  - Merged release manifest cross-check: INTERNET count=0
    (evidence/qa/ac4-permissions-manifest.txt). INTERNET is present only in the
    debug/profile source manifests (`:6`), not merged into release
    (evidence/qa/devmd-citation-check.txt).
  - The `android.permission.DUMP` seen in the merged manifest is a component-guard
    attribute (androidx ProfileInstaller), not a requested permission
    (evidence/qa/ac4-dump-component.txt) — benign.

- **AC5** (R8 release variant runs on device; core loop; no crash) → **met**.
  - Install + launch on emulator-5554: install_exit=0, am_start_exit=0,
    topResumedActivity=…/.MainActivity (evidence/qa/ac5-install-launch.txt,
    ac5-runtime-state.txt).
  - Launch screenshot rendered correctly under R8 (stats panel, "Blue" keycap with
    glow, four switch chips, settings gear): evidence/qa/smoke/screenshot-1-launch.png.
  - Core loop verified: after 5 keycap taps the counters read 누적=5, 세션=5, CPM=5,
    최고 CPM=5 (evidence/qa/smoke/screenshot-2-after-taps.png) — tap handling and state
    survive minification.
  - Logcat clean under R8: 0 FATAL EXCEPTION, 0 ClassNotFound/NoClassDefFound/
    NoSuchMethod, 0 crashes, 0 E/flutter; audioplayers
    (`xyz.luan.audioplayers.player`) successfully calls `requestAudioFocus()` on tap →
    sound backend not stripped; the only app-pid E line is the benign non-debuggable
    "jdwp agent" message (evidence/qa/ac5-logscan.txt, ac5-app-pid-errors.txt,
    ac5-logcat.txt).
  - NOTE: per-tap *audible* sound was not asserted (only that the audio backend ran
    and requested focus) — consistent with dev.md's honest UNVERIFIED; not an AC
    requirement.

- **AC6** (analyze clean, format exit 0, tests green) → **met**.
  - Format EXIT_CODE=0, Analyze "No issues found!" EXIT_CODE=0, Test "+127 All tests
    passed!" EXIT_CODE=0 (evidence/qa/format.txt, analyze.txt, test.txt).

## Findings
None.

VERIFIED — every applicable test-pyramid layer passed on QA's own evidence, the
document audit is fully BACKED, and all acceptance criteria (AC1–AC6) are met. The
two secrets remain untracked and unstageable before and after the build, and the
release AAB/APK is signed by the upload key (not the debug key). The R8-minified
release variant launches and runs the core loop without crashes.
