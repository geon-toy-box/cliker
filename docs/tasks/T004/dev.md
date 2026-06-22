# Dev report — T004 (Audio service + haptics)

## Status
Implemented and self-checked; awaiting QA. All applicable test-pyramid layers
green this session, including the AC5 build smoke now that the audio backend is
**audioplayers** (the Planner's authorized swap from the infeasible soundpool —
see task.md "Planner amendment (2026-06-22)").

## Summary
Built a low-latency click-sound service with a test-injectable backend
abstraction (`SoundBackend` → `AudioPlayersBackend` / `ClickSoundPlayer`) and a
strength-bucketed `Haptics` service, plus their Riverpod providers, with full
unit + widget coverage. The native plugin (audioplayers) integrates with the
Android Gradle build: `flutter build apk --debug` succeeds and produces an APK.

## History (why audioplayers, not soundpool)
The task originally specified soundpool. soundpool 2.4.1 (pub.dev latest, marked
discontinued) uses the removed v1 Android embedding API (`PluginRegistry
.Registrar`) and fails `:soundpool:compileDebugKotlin` on Flutter 3.41.7. I
reported this BLOCKED; the Planner confirmed the swap to audioplayers and
amended task.md. The original soundpool failure is preserved at
`evidence/dev/build-blocker-rootcause.txt` for history.

## Changes
This project is not a git repo (`Is directory a git repo: No`), so there is no
`git diff --stat`. Files created/modified this session (verified by `ls -l` and
the evidence/dev/ listing):

- `pubspec.yaml:39` — `audioplayers: ^6.7.1` (resolved 6.7.1). soundpool removed.
  Done via `flutter pub remove soundpool && flutter pub add audioplayers`. (also
  updated `pubspec.lock`.) audioplayers is the only audio dep; no other deps added.
- `lib/audio/click_sound_player.dart` (new) —
  - `abstract class SoundBackend` (`load`/`play`/`dispose`) — unchanged shape.
  - `class AudioPlayersBackend implements SoundBackend` — per-asset [AudioPool]
    in `PlayerMode.lowLatency`; `load` strips the leading `assets/` (AssetSource
    auto-prefixes it) and returns an int id indexing the pool list; `play` →
    `pool.start(volume:)`; `dispose` disposes every pool.
  - `class ClickSoundPlayer(SoundBackend)` — `init()` preloads all 8 catalog
    down/up assets into a `Map<String,int>`, `playDown`/`playUp`, `bool muted`,
    `dispose()`. (backend-agnostic; unchanged by the swap.)
  - `clickSoundPlayerProvider` — now constructs `AudioPlayersBackend`.
- `lib/services/haptics.dart` (new) — `Haptics{ Future<void> click(double);
  bool enabled }` mapping strength buckets (`<0.5` lightImpact, `[0.5,0.8]`
  mediumImpact, `>0.8` heavyImpact); `hapticsProvider`. (unchanged by the swap.)
- `test/unit/click_sound_player_test.dart` (new) — AC1/AC2/AC3 via a FakeBackend.
  **Unchanged by the swap** (depends only on `SoundBackend`/`ClickSoundPlayer`).
- `test/widget/haptics_test.dart` (new) — AC4 via `setMockMethodCallHandler` on
  `SystemChannels.platform` capturing `HapticFeedback.vibrate` args. **Unchanged.**

## Acceptance criteria → evidence

- **AC1** (`init()` loads exactly the 8 down/up assets by correct path):
  PASS — `evidence/dev/test-new.txt` "(AC1) loads exactly the 8 catalog down/up
  assets, by correct path" (`+0`). Asserts `backend.loaded` length 8 and
  set-equals the catalog down/up paths. Code:
  `lib/audio/click_sound_player.dart:95-108`.
- **AC2** (`playDown`/`playUp` use the mapped soundId for the right asset; ≥2
  switches): PASS — `evidence/dev/test-new.txt` "(AC2) … for blue" (`+2`) and
  "(AC2) uses a different soundId for a second switch (red)" (`+3`). Code:
  `lib/audio/click_sound_player.dart:112-131`.
- **AC3** (`muted=true` ⇒ no backend.play): PASS — `evidence/dev/test-new.txt`
  "(AC3) muted=true suppresses both playDown and playUp" (`+5`). Code:
  `lib/audio/click_sound_player.dart:122-125`.
- **AC4** (`Haptics.click` invokes the bucket's HapticFeedback platform method;
  `enabled=false` ⇒ zero platform calls): PASS — `evidence/dev/test-new.txt`
  `+9`..`+17` (light/medium/heavy + boundaries 0.49/0.5/0.8/0.9/1.0, and
  "enabled=false … zero platform calls"). Code: `lib/services/haptics.dart:26-37`.
- **AC5** (`flutter build apk --debug` succeeds with the native audio plugin
  integrated): PASS — `evidence/dev/build-apk.txt`
  "✓ Built build/app/outputs/flutter-apk/app-debug.apk", EXIT_CODE=0. Artifact
  on disk: `build/app/outputs/flutter-apk/app-debug.apk`, 150,940,271 bytes
  (~144M debug). This proves audioplayers integrates with the Android Gradle build.
- **AC6** (`flutter analyze` "No issues found!"; `dart format` exit 0):
  PASS — `evidence/dev/analyze.txt` "No issues found!" EXIT_CODE=0;
  `evidence/dev/format.txt` "0 changed" EXIT_CODE=0.

## Verification evidence
- pub swap:  `evidence/dev/pubget.txt` — EXIT_CODE=0 (`- soundpool`, `+ audioplayers 6.7.1`).
- Format:    `evidence/dev/format.txt` — "Formatted 24 files (0 changed)", EXIT_CODE=0.
- Analyze:   `evidence/dev/analyze.txt` — "No issues found!", EXIT_CODE=0.
- Tests (full): `evidence/dev/test.txt` — "All tests passed!" `+96`, EXIT_CODE=0
  (78 pre-existing + 18 new). The concurrent reporter overwrites in-progress
  lines, so the canonical per-test listing of the new files is in test-new.txt.
- Tests (new files, expanded): `evidence/dev/test-new.txt` — 18 tests
  (9 unit + 9 widget), "All tests passed!" `+18`, EXIT_CODE=0.
  (Planner 2026-06-22: corrected miscount 19→18 / 10 unit→9 to match evidence per qa.md.)
- Build (AC5): `evidence/dev/build-apk.txt` — "✓ Built …app-debug.apk",
  EXIT_CODE=0; artifact confirmed via `ls -l` (150,940,271 bytes).
- History: `evidence/dev/build-blocker-rootcause.txt` — the original soundpool
  build failure (kept for the record; no longer the active backend).

## AudioPool API used (audioplayers 6.7.1)
- Construct per-asset: `AudioPool.createFromAsset(path: <asset without leading
  "assets/">, maxPlayers: 4, playerMode: PlayerMode.lowLatency)`.
- Play: `await pool.start(volume: volume)`.
- Dispose: `await pool.dispose()` per pool.
Verified against the resolved source at
`~/.pub-cache/hosted/pub.dev/audioplayers-6.7.1/lib/src/audio_pool.dart`
(`createFromAsset` L92, `start` L110, `dispose` L187) and by `flutter analyze`
returning clean.

## Self-audit
- Not a git repo, so no `git diff --stat`; the Changes list is reconciled
  against `ls -l` of the four created files + the `pubspec.yaml:39` /
  `pubspec.lock` audioplayers entries shown in this session's tool output, and
  `grep -rn soundpool lib/ test/` returns NONE.
- Every PASS line cites an evidence file in `evidence/dev/` carrying an
  `EXIT_CODE=` line that matches the claim; AC5's artifact size was read via
  `ls -l` this session.
- I did not edit any file under `evidence/` by hand; all were produced via the
  capture idiom (`{ cmd; echo EXIT_CODE=$?; } 2>&1 | tee …`).

## Known limitations / UNVERIFIED
- **Runtime audio is UNVERIFIED.** The build compiles and links audioplayers,
  but actual on-device playback (asset decode, `AudioPool.start` audibly firing,
  latency feel) is **not** exercised here — only `ClickSoundPlayer`'s
  orchestration over a FakeBackend is unit-tested. Real-audio verification is
  the T006 runtime smoke per the spec.
- `AudioPlayersBackend` itself has no direct unit test (it touches the platform
  plugin); it is covered only indirectly by AC5 (it compiles/integrates). Its
  asset-prefix stripping and `start(volume:)` behavior are UNVERIFIED at runtime.
- `<0.5` bucket: spec allowed "selectionClick()/lightImpact()"; I chose
  `lightImpact()` for a consistent light→medium→heavy impact gradient. If QA/
  Planner prefer `selectionClick()`, it is a one-line change plus a test arg.
