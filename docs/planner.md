---
project: cliker
package: cliker
org: com.secondsyndrome
created: 2026-06-22
status: planning
tags: [toybox, project, planner]
---

# cliker — Planner

> Master plan owned by the **Planner**. This is the single source of truth for
> what the product is and what work remains. Workers never edit this file; they
> write `docs/tasks/<id>/{dev,qa}.md`, and the Planner reflects verified results
> back here. Every status here must trace to evidence in a task's `evidence/`.

## Product vision
**cliker — LED 클릭커 키캡 (스트레스 해소 앱).** 화면 중앙의 큼직한 기계식 키캡
하나를 누르면 진짜 키보드처럼 **타건음(사운드) + 진동(햅틱) + LED 빛 효과**가
터지고, 누른 만큼 **클릭 카운터/통계**가 쌓인다. 멍하니 또는 집중해서 키캡을
연타하며 스트레스를 푸는 가벼운 피젯(fidget) 토이. 청축·갈축·적축 등 여러 기계식
스위치 음색을 골라 자기 취향의 타건감을 만든다. Android 전용, 오프라인 동작,
권한 최소(진동만).

대상: 키보드 타건감/ASMR·피젯 토이를 좋아하는 사람, 잠깐의 스트레스 해소가 필요한
사람. "좋다"의 기준 = 탭 → 피드백 지연이 체감되지 않고(저지연), 연타가 끊기지 않으며,
한 번 더 누르고 싶은 만족감.

## Definition of "shippable"
- [ ] 핵심 루프가 실기기에서 끝까지 동작: 키캡 탭 → 저지연 타건음 + 진동 + LED + 카운터 증가 (smoke evidence)
- [ ] 콜드 스타트/네트워크 없음/권한 거부/회전에서 크래시 없음
- [ ] 스위치 선택·LED·통계가 앱 재시작 후에도 유지(영구 저장)
- [ ] 정적 분석 clean(`No issues found!`), 테스트 피라미드 green, `dart format` clean
- [ ] Google Play Console 업로드 가능: 실 app id, 릴리스 서명, 앱 아이콘/이름, AAB 빌드 성공, 스토어 등록 메타데이터 준비

## Milestones
| # | Milestone | Goal | Status |
|---|-----------|------|--------|
| M1 | Core clicker MVP | 단일 대형 키캡 탭 → 타건음+진동+LED+카운터가 저지연으로 동작하고 스위치 선택/통계가 영구 저장되는 동작하는 앱 | TODO |
| M2 | Polish & customization | LED 효과 모드(리플·RGB 사이클·반응형), 색상 커스터마이즈, 설정 화면, 통계 패널(누적·세션·CPM·최고기록) | TODO |
| M3 | Play Store readiness | 앱 아이콘/이름, app id 확정, 릴리스 서명(keystore), 버전, AAB 빌드, 권한 점검, 스토어 등록 메타데이터·개인정보처리방침 | TODO |

## Task backlog
> Statuses: TODO · IN_PROGRESS · BLOCKED · NEEDS_FIX · VERIFIED · DONE
> A task may only become VERIFIED via QA, and DONE only with a commit hash.

| id | title | milestone | depends on | status | verified-by |
|----|-------|-----------|------------|--------|-------------|
| T001 | Foundation: dark RGB theme tokens | M1 | — | DONE | qa.md PASS · 9593ce2 |
| T002 | Switch domain catalog + synthesized switch sound assets | M1 | T001 | DONE | qa.md PASS · 52b146d |
| T003 | Persistence + settings & stats state (Riverpod) | M1 | T002 | DONE | qa.md PASS · 4cfc6d0 |
| T004 | Audio service (low-latency soundpool) + haptics service | M1 | T002 | TODO | — |
| T005 | Keycap widget + LED ripple/glow effects | M1 | T001 | DONE | qa.md PASS · 689d017 |
| T006 | Home screen wiring (keycap + audio + haptics + stats + switch selector) | M1 | T003,T004,T005 | TODO | — |
| T007 | Settings & customization (LED modes, color, sound/haptic toggles) | M2 | T006 | TODO | — |
| T008 | Stats panel (total · session · CPM · best) + reset | M2 | T006 | TODO | — |
| T009 | App identity: launcher icon + app name + versioning | M3 | T006 | TODO | — |
| T010 | Release build: signing config + AAB + permissions audit | M3 | T009 | TODO | — |
| T011 | Store listing metadata + privacy policy | M3 | T010 | TODO | — |

## Decisions log
<!-- Architecture/product decisions, dated, with the reasoning. Prevents re-litigating. -->
- 2026-06-22: Stack = Flutter (Android-only) + Riverpod. Testability + compile-time safety.
- 2026-06-22: 레이아웃 = **단일 대형 키캡**(사용자 선택). MVP로 깔끔하고 몰입감 높음.
- 2026-06-22: 피드백 4종 모두 포함(사용자 선택): 타건음 + 햅틱 + LED + 카운터/통계.
- 2026-06-22: 스위치 = **여러 종 선택**(사용자 선택). v1 카탈로그: 청축(blue)·갈축(brown)·적축(red)·흑축(black).
- 2026-06-22: 사운드 = 라이선스 리스크 회피 위해 **합성(synthesized) WAV**를 커밋된 파이썬 스크립트로 생성·번들. 외부 다운로드/저작권 자산 미사용.
- 2026-06-22: 저지연 연타 위해 오디오는 ~~soundpool~~ → **audioplayers**(`AudioPool`, low-latency)로 변경. 이유(T004 BLOCKED): soundpool 2.4.1(최신·discontinued)이 제거된 v1 Flutter Android 임베딩(`PluginRegistry.Registrar`)을 써서 Flutter 3.41.7에서 `:soundpool:compileDebugKotlin` 컴파일 실패, 더 올릴 버전도 없음. Dart는 `SoundBackend`로 플러그인을 격리해둬서 백엔드 구현(SoundpoolBackend→AudioPlayersBackend)과 프로바이더 배선만 교체, 인터페이스·테스트 불변. 탭다운=down음, 탭업=up음 유지.
- 2026-06-22: 설정/통계 영구 저장 = **shared_preferences**(단순 key-value). devlingo는 hive를 썼으나 여기선 카운터·토글 위주라 더 가벼운 선택.
- 2026-06-22: app id = `com.secondsyndrome.cliker` (이메일 도메인 2ndsyndrome.com 기반; 'com.2ndsyndrome'은 세그먼트가 숫자로 시작해 Android 규칙 위반이라 secondsyndrome로 변환). 퍼블리시 전 사용자 확정 필요.
- 2026-06-22: 디자인 = 다크 + 네온 RGB 게이밍 무드(키보드 LED 감성). 라이트 테마 없음(v1).

## Open questions (for the user)
<!-- Things the Planner needs the user to decide. Resolve via tiki-taka, then move to Decisions. -->
- app id `com.secondsyndrome.cliker` 그대로 갈지, 다른 reverse-DNS를 쓸지 (퍼블리시 전 확정).
- 릴리스 keystore: 내가 업로드 키스토어를 생성해 드릴지(사용자가 안전 백업), 아니면 사용자가 직접 만들지 (M3 진입 시 결정).
- 앱 표시 이름: "cliker" / "클리커" / 다른 이름?

## Reflected results
<!-- Append-only. Each entry is the Planner's audited summary of a completed task,
     citing the qa.md verdict and commit it trusts. -->
- 2026-06-22 · **T001 DONE** (commit `9593ce2`, qa.md `## Verdict: PASS`). 다크+네온 RGB 디자인 토큰 확정: `AppColors`(bg/surface/keycap/text + 6색 ledPalette + 스위치 스템색, accentDefault=neonCyan), `AppSpacing`/`AppRadius`, `appTheme()`는 명시적 dark `ColorScheme`(primary=neonCyan, fromSeed 미사용). Planner 직접 확인: `flutter analyze` clean, `flutter test` 16 green, pubspec drift 없음. 신규 패키지 의존성 추가 없음(스코프 준수).
- 2026-06-22 · **T002 DONE** (commit `52b146d`, qa.md `## Verdict: PASS`). 스위치 카탈로그 `SwitchCatalog`=[blue 청축, brown 갈축, red 적축, black 흑축], stem/LED색은 `AppColors` 참조(하드코딩 없음). `tools/gen_sounds.py`(파이썬 표준 라이브러리만, 결정적)가 8개 WAV(44100Hz mono 16-bit)를 `assets/sounds/`에 생성·번들, pubspec 등록. 35 신규 단위 테스트. Planner 직접 확인: 내가 직접 재생성→black_down.wav SHA-256 바이트 동일(결정적 ✓), pubspec은 assets만 추가(신규 패키지 의존성 0), analyze clean, 51 tests green.
- 2026-06-22 · **T003 DONE** (commit `4cfc6d0`, qa.md `## Verdict: PASS`). `shared_preferences` 영구 저장 + Riverpod 상태: `SettingsNotifier`(선택 스위치/사운드·햅틱 토글/LedMode/LED색 모두 영구), `StatsNotifier`(누적·최고 영구, 세션·CPM 메모리, trailing-60s CPM, reset). 20 신규 단위 테스트. QA가 "fresh container=재시작" 테스트가 실제로 비영속을 감지함을 falsification-probe로 증명. Planner 직접 확인: 신규 의존성 shared_preferences 1개뿐, analyze clean, 71 tests green.
- 2026-06-22 · **T005 DONE** (commit `689d017`, qa.md `## Verdict: PASS`). 자기완결 `Keycap` 위젯(AppColors 베벨, 60ms 다운/90ms 스냅업 scale+트래블, ledColor 글로우, 누름마다 자가제거 `LedRipple`, onPressDown/onPressUp 콜백) + 5 위젯 테스트 + 2 골든(미눌림/눌림). QA 어드버서리얼: 눌림상태·리플제거 단정이 no-op이 아님을 증명, 골든은 --update-goldens 없이 일치. Planner 직접 확인: 신규 의존성 0, analyze clean, 78 tests green. (오디오/햅틱/통계/스크린 연결은 T006)
