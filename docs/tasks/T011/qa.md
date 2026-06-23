# QA verdict — T011 (Store listing metadata + privacy policy)

## Verdict: PASS

All six acceptance criteria are met with evidence QA generated this session under
`docs/tasks/T011/evidence/qa/`. The document audit of `dev.md` is fully BACKED
(every acceptance-criterion claim reproduced independently). App is unchanged and
regression-free.

## Independent test results (test pyramid)
- Format:      N/A — no `.dart` files changed (docs/assets only). `git diff --stat`
               for lib/ test/ pubspec.yaml android/ is empty — evidence/qa/ac6-git-status.txt
- Analyze:     evidence/qa/analyze.txt — "No issues found! (ran in 2.1s)" — EXIT_CODE=0
- Unit+Widget: evidence/qa/test.txt — "+127: All tests passed!" — EXIT_CODE=0
               (full `flutter test`; 127 reproduced, matches dev claim)
- Golden:      included in the +127 run (no separate golden tag run; suite unchanged)
- Coverage:    N/A — docs-only task, no behavior change to gate
- Integration: N/A per task.md test-plan (no app code change); covered by widget suite
- Build:       N/A — no code change. T010 AAB reused, confirmed on disk:
               evidence/qa/ac5-checklist-refs.txt — build/app/outputs/bundle/release/app-release.aab, 41,491,782 bytes (~40MB)
- Smoke:       evidence/qa/smoke/screenshot-1.png (genuine cliker UI: stats panel,
               neon "Red" keycap w/ magenta solid LED, switch selector) +
               evidence/qa/smoke/logcat-scan.txt — "NO FATAL / NO CRASH LINES FOUND";
               ActivityTaskManager "Fully drawn ... MainActivity". App launched
               live on emulator-5554 (Android 15). No fatal.

## Document audit
evidence/qa/doc-audit.txt — 17 acceptance-criterion-relevant claims, all BACKED
(result claims independently reproduced). Zero UNBACKED, zero CONTRADICTED claims
bearing on any AC. One cosmetic imprecision noted (C18: dev.md says the
`docs/tasks/T011/` subtree is gitignored, but `git status` does list
`?? docs/tasks/T011/dev.md`) — does not touch any acceptance criterion.

## Spec conformance (acceptance criteria)

- AC1 — all 7 files exist under docs/store/ → MET.
  evidence/qa/ac1-files.txt — listing-ko.md, listing-en.md, privacy-policy.md,
  privacy-policy.html, data-safety.md, content-rating.md, store-checklist.md all EXIST. EXIT_CODE=0.

- AC2 — title/short/full within Play limits (30/80/4000) → MET.
  QA's OWN python3 code-point measurement (strings extracted directly from the
  listing files) — evidence/qa/ac2-charcounts.txt, ordering confirmed in
  evidence/qa/ac2-fence-check.txt:
  | Field    | QA-measured | Limit | Status |
  |----------|------------:|------:|--------|
  | KO title |          20 |    30 | OK |
  | KO short |          49 |    80 | OK |
  | KO full  |        1022 |  4000 | OK |
  | EN title |          25 |    30 | OK |
  | EN short |          73 |    80 | OK |
  | EN full  |        1949 |  4000 | OK |
  My numbers match the dev's claims exactly; none exceed the limit.

- AC3 — privacy policy matches real app (local-only, no network/collection) → MET.
  - No INTERNET in release/main manifest — evidence/qa/ac3-manifest.txt +
    ac3-main-manifest-full.txt (main manifest has ZERO uses-permission lines;
    INTERNET only in debug/ + profile/, excluded from release AAB).
  - No network code in lib/ — evidence/qa/ac3-network-grep.txt (zero matches for
    HttpClient/Socket/http/dio/WebSocket/InternetAddress/etc.).
  - No ads/analytics deps — pubspec.yaml has only flutter, cupertino_icons,
    flutter_riverpod, shared_preferences, audioplayers — evidence/qa/ac3-storage-audio.txt
    + doc-claims-spotcheck.txt (pubspec.yaml:30-39).
  - Local-only storage via SharedPreferences; audio is local assets
    (AudioPool.createFromAsset) — evidence/qa/ac3-storage-audio.txt.
  - privacy-policy.html is standalone (DOCTYPE/html/head/body, inline CSS, only a
    mailto link; no external deps) and content matches privacy-policy.md.
  The policy's "no data collected/transmitted, local-only, no INTERNET, no
  ads/analytics" claims are accurate against the actual app.

- AC4 — ≥2 valid PNG phone screenshots of the real app → MET.
  evidence/qa/ac4-screenshots-file.txt — 6 PNGs, all "PNG image data, 320 x 640".
  QA visually confirmed all 6 are genuine cliker UI (home keycap "Blue" cyan LED;
  tap ripple at counter 18; settings sheet w/ sound/haptic + LED color/mode;
  switch selection "Red"; magenta solid LED), plus an independent live capture
  (smoke/screenshot-1.png). Resolution 320×640 — low but meets Play's ≥320px-per-side
  minimum; disclosed as a re-capture caveat.

- AC5 — checklist lists all upload items + points to each artifact → MET.
  store-checklist.md covers AAB (build/.../app-release.aab, T010), launcher icon
  (T009 mipmaps — confirmed present, doc-claims-spotcheck.txt) + 512 listing icon
  (assets/icon/icon.png 1024px — confirmed), KO/EN listings, screenshots dir,
  privacy URL (user-hosted), data-safety, content rating, free pricing,
  distribution countries, feature graphic. Mapping table at §"자료 매핑 요약".
  User-only steps clearly flagged 🧑: Play account/app creation (A), AAB upload
  (B), privacy URL hosting (E), feature graphic ("미준비 — 사용자가 제작 필요", D).
  File:line refs verified: build.gradle.kts:38 = com.geontoybox.cliker,
  pubspec.yaml:19 = 1.0.0+1 — evidence/qa/ac5-checklist-refs.txt.

- AC6 — app code/tests unchanged, no regression → MET.
  - flutter analyze "No issues found!" EXIT_CODE=0 — evidence/qa/analyze.txt
  - flutter test "+127: All tests passed!" EXIT_CODE=0 — evidence/qa/test.txt
  - git status shows ONLY docs/ additions (docs/store/* + docs/tasks/T011/dev.md);
    lib/, test/, pubspec.yaml, android/ all clean — evidence/qa/ac6-git-status.txt

## Caveat honesty check
All dev-disclosed limitations are honest and disclosed in store-checklist.md and/or
dev.md, and the corresponding user-action items are flagged 🧑:
- Screenshots 320×640 (small AVD): true — QA's live capture is also 320×640;
  disclosed in checklist §D as optional 🧑 re-capture.
- Feature graphic 1024×500 NOT prepared: disclosed as 🧑 "미준비, 사용자가 제작 필요".
- Category (Entertainment/Tools) and IARC "Everyone": disclosed as predictions, with
  the explicit note that final rating is assigned by IARC after user submission.
- Privacy-policy URL not live: disclosed — user must host privacy-policy.html.
These are acceptable per task.md "Out of scope" (actual upload/hosting is the user's).

## Findings
None. No defect found across all layers.
