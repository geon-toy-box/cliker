# Dev report — T011 (Store listing metadata + privacy policy)

## Summary
Prepared all Play Console registration material under `docs/store/` (Korean +
English listings, privacy policy in MD + standalone HTML, data-safety answers,
IARC content-rating guidance, full upload checklist) plus 6 real-app screenshots
captured from `emulator-5554`. This task is docs/assets only — no `lib/`, `test/`,
or `pubspec.yaml` changes. App remains analyze-clean and 127 tests green.

Status: implemented and self-checked; awaiting QA.

## Changes
All additions are untracked files under `docs/store/` (confirmed by
`git status --porcelain --untracked-files=all` — see Self-audit). No tracked file
was modified.

- `docs/store/listing-ko.md` — Korean Play listing (title/short/full + category, tags, contact)
- `docs/store/listing-en.md` — English Play listing (title/short/full + category, tags, contact)
- `docs/store/privacy-policy.md` — KO+EN privacy policy (no data collected, local-only)
- `docs/store/privacy-policy.html` — standalone browser-openable privacy policy for hosting
- `docs/store/data-safety.md` — Play Data safety form answers (no collection/sharing)
- `docs/store/content-rating.md` — IARC questionnaire guidance (expected Everyone)
- `docs/store/store-checklist.md` — full upload checklist, each item → its artifact source
- `docs/store/screenshots/01-home-keycap.png` — home/keycap (Blue, cyan LED)
- `docs/store/screenshots/02-tap-counter.png` — tap moment: LED ripple + counter at 18
- `docs/store/screenshots/03-settings-sheet.png` — settings sheet (sound/haptic, LED color/mode)
- `docs/store/screenshots/04-switch-selection.png` — switch selection (Red selected, "Red" label)
- `docs/store/screenshots/05-led-customize.png` — LED color (magenta) + mode (solid) selected
- `docs/store/screenshots/06-home-magenta-solid.png` — home with magenta solid LED applied

## Tests added
None — this is a docs/assets task. No app behavior changed, so no unit/widget/
golden/integration tests were added (Test plan in task.md marks these N/A).
Instead, the verification is: (a) measured char counts, (b) real-device
screenshots, (c) code/manifest cross-check for the privacy claim, (d) app
no-regression (analyze + test).

## Verification evidence
- Format:    N/A — no Dart files changed (docs/assets only). `git status` shows
             zero `.dart` changes (evidence/dev/git-status.txt).
- Analyze:   `evidence/dev/analyze.txt` — "No issues found!", EXIT_CODE=0
- Unit+Widget+Integration (full suite): `evidence/dev/test.txt` —
             "+127: All tests passed!", EXIT_CODE=0 (no regression; suite unchanged)
- Build:     N/A — no code change. AAB is the T010 artifact, present at
             `build/app/outputs/bundle/release/app-release.aab` (~40MB), reused by checklist.
- Char counts: `evidence/dev/charcounts.txt` (see AC2 below)
- Screenshots: `docs/store/screenshots/*.png` — 6 valid PNGs (320×640), real app
- Runtime smoke (during capture): `evidence/dev/logcat-scan.txt` —
             "NO FATAL / NO CRASH LINES FOUND", EXIT_CODE=0
- Git status: `evidence/dev/git-status.txt` — only `docs/store/` additions

## Acceptance criteria → evidence

### AC1 — all 7 store files exist
PASS (self-checked). `docs/store/` contains: listing-ko.md, listing-en.md,
privacy-policy.md, privacy-policy.html, data-safety.md, content-rating.md,
store-checklist.md. Confirmed via `ls`/`git status` (evidence/dev/git-status.txt
lists each).

### AC2 — title/short/full within Play limits (30/80/4000)
PASS (self-checked). Measured by `python3 len()` (Unicode code points; Korean
char = 1) in `evidence/dev/charcounts.txt`. The script's strings are verbatim
copies of what appears in the listing files:

| Field | Chars | Limit | Status |
|-------|------:|------:|--------|
| KO title | 20 | 30 | OK |
| KO short | 49 | 80 | OK |
| KO full  | 1022 | 4000 | OK |
| EN title | 25 | 30 | OK |
| EN short | 73 | 80 | OK |
| EN full  | 1949 | 4000 | OK |

Note: the EN short description was initially 81 chars (over); I trimmed it to
73 ("…haptics & LEDs. Fully offline.") and re-measured to confirm ≤80. The
listing files' stated counts match these measured values.

### AC3 — privacy policy matches real app behavior (local-only, no network/collection)
PASS (self-checked) via code/manifest cross-check:
- Release/main manifest declares **0 permissions** — no INTERNET:
  `android/app/src/main/AndroidManifest.xml` has zero `uses-permission` lines.
  (INTERNET appears only in `android/app/src/debug/` and `.../profile/`
  manifests — Flutter's dev-tooling default, NOT part of the release AAB.)
- No network code in `lib/`: grep for `HttpClient|HttpServer|RawSocket|Socket(|
  http(s)://|package:http|dio|web_socket` returned nothing (only `audioplayers`'
  `AudioPool`, which is local audio playback, not network).
- No ads/analytics deps: pubspec.yaml has only flutter, cupertino_icons,
  flutter_riverpod, shared_preferences, audioplayers (pubspec.yaml:30-39).
- Local storage confirmed: `shared_preferences` used in
  `lib/persistence/settings_store.dart:2`, `lib/providers/settings_providers.dart`,
  `lib/providers/stats_providers.dart`, `lib/main.dart`.
The policy's claims (no collection, no transmission, local-only via
SharedPreferences, no INTERNET permission, no ads/analytics) are accurate.

### AC4 — ≥2 valid PNG phone screenshots of the real app
PASS (self-checked). 6 PNGs in `docs/store/screenshots/`, each `file`-verified as
"PNG image data, 320 x 640" and captured via
`adb -s emulator-5554 exec-out screencap -p`. Each was visually confirmed to be
the real cliker UI (stats panel 누적/세션/CPM/최고, neon keycap, switch selector,
settings sheet). 320×640 meets Play's ≥320px-per-side minimum; a caveat to
re-capture at higher resolution for store quality is recorded in store-checklist.md
and Known limitations.

### AC5 — checklist lists all upload items + points to each artifact source
PASS (self-checked). `docs/store/store-checklist.md` covers: AAB
(`build/app/outputs/bundle/release/app-release.aab`, T010), launcher icon (T009
mipmaps in AAB) + 512 listing icon (`assets/icon/icon.png`), KO/EN listings,
screenshots dir, privacy URL (user-hosted `privacy-policy.html`), data-safety,
content rating, free pricing, target countries. User-only steps are marked 🧑;
prepared assets are marked 📄. A summary mapping table is included.

### AC6 — app code/tests unchanged, no regression
PASS (self-checked).
- `evidence/dev/analyze.txt` — "No issues found!", EXIT_CODE=0
- `evidence/dev/test.txt` — "+127: All tests passed!", EXIT_CODE=0
- `evidence/dev/git-status.txt` — only `docs/store/` untracked additions;
  `lib/`, `test/`, `pubspec.yaml` all clean (verified: `git status --porcelain
  lib/ test/ pubspec.yaml` returned empty).

## Self-audit
Confirmed: every claim above is backed by a file in evidence/ or a quoted source
file. `git status` shows only `docs/store/` additions; no tracked file modified.

`git status --porcelain --untracked-files=all` (from evidence/dev/git-status.txt):
```
?? docs/store/content-rating.md
?? docs/store/data-safety.md
?? docs/store/listing-en.md
?? docs/store/listing-ko.md
?? docs/store/privacy-policy.html
?? docs/store/privacy-policy.md
?? docs/store/screenshots/01-home-keycap.png
?? docs/store/screenshots/02-tap-counter.png
?? docs/store/screenshots/03-settings-sheet.png
?? docs/store/screenshots/04-switch-selection.png
?? docs/store/screenshots/05-led-customize.png
?? docs/store/screenshots/06-home-magenta-solid.png
?? docs/store/store-checklist.md
```
(The `docs/tasks/T011/` evidence subtree is not listed because that path is
gitignored in this repo; it exists on disk for QA at the standard evidence paths.)

The Changes list above equals these 13 additions exactly.

## Known limitations / UNVERIFIED
- Screenshots are 320×640 (the connected `emulator-5554` is a small AVD at
  density 160). This meets Play's ≥320px-per-side minimum but is low resolution
  for a polished store page. UNVERIFIED whether the user wants higher-res
  captures; flagged in store-checklist.md §D as an optional user re-capture.
- The 1024×500 **feature graphic** is a Play-required asset that is NOT prepared
  here (no design source exists in-repo to generate it deterministically). Marked
  as a user-to-create item in the checklist.
- Category recommendation (Entertainment over Tools) and the IARC "Everyone"
  outcome are **predictions/guidance**, not Play-confirmed verdicts — the actual
  rating is assigned by IARC after the user submits the questionnaire.
- The privacy-policy URL is not live: the user must host `privacy-policy.html`
  (e.g. GitHub Pages) and paste the resulting URL into Play Console.
