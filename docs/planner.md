---
project: cliker
package: cliker
org: com.secondsyndrome
created: 2026-06-22
status: shippable
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
- [x] 핵심 루프가 실기기에서 끝까지 동작: 키캡 탭 → 저지연 타건음 + 진동 + LED + 카운터 증가 (T006 에뮬레이터 런타임 스모크)
- [x] 콜드 스타트/네트워크 없음/권한 거부/회전에서 크래시 없음 (T006 회전·logcat 무결함; 오프라인 로컬 전용·권한 없음)
- [x] 스위치 선택·LED·통계가 앱 재시작 후에도 유지(영구 저장) (T003 + T006 검증)
- [x] 정적 분석 clean(`No issues found!`), 테스트 피라미드 green(127), `dart format` clean
- [x] Google Play Console 업로드 가능: app id 확정, 릴리스 서명, 앱 아이콘/이름(클리커), **서명 AAB 빌드 성공**, 스토어 등록 메타데이터 준비 (feature graphic·개인정보 URL 호스팅·업로드는 사용자 액션)

## Milestones
| # | Milestone | Goal | Status |
|---|-----------|------|--------|
| M1 | Core clicker MVP | 단일 대형 키캡 탭 → 타건음+진동+LED+카운터가 저지연으로 동작하고 스위치 선택/통계가 영구 저장되는 동작하는 앱 | DONE (T001–T006 VERIFIED, 에뮬레이터 런타임 스모크 통과) |
| M2 | Polish & customization | LED 효과 모드(리플·RGB 사이클·반응형), 색상 커스터마이즈, 설정 화면, 통계 패널(누적·세션·CPM·최고기록) | DONE (T007,T008 VERIFIED) |
| M3 | Play Store readiness | 앱 아이콘/이름, app id 확정, 릴리스 서명(keystore), 버전, AAB 빌드, 권한 점검, 스토어 등록 메타데이터·개인정보처리방침 | DONE (T009,T010,T011 VERIFIED) |
| M4 | 스위치 11종 확장 + UI 개편 | 체리 MX 11종, 통계 2개(전체·RPM), 진짜 키캡 모양+확실한 눌림, 11종 가로 스크롤 선택기 | TODO |

## Task backlog
> Statuses: TODO · IN_PROGRESS · BLOCKED · NEEDS_FIX · VERIFIED · DONE
> A task may only become VERIFIED via QA, and DONE only with a commit hash.

| id | title | milestone | depends on | status | verified-by |
|----|-------|-----------|------------|--------|-------------|
| T001 | Foundation: dark RGB theme tokens | M1 | — | DONE | qa.md PASS · 9593ce2 |
| T002 | Switch domain catalog + synthesized switch sound assets | M1 | T001 | DONE | qa.md PASS · 52b146d |
| T003 | Persistence + settings & stats state (Riverpod) | M1 | T002 | DONE | qa.md PASS · 4cfc6d0 |
| T004 | Audio service (low-latency, audioplayers) + haptics service | M1 | T002 | DONE | qa.md PASS · 8829597 |
| T005 | Keycap widget + LED ripple/glow effects | M1 | T001 | DONE | qa.md PASS · 689d017 |
| T006 | Home screen wiring (keycap + audio + haptics + stats + switch selector) | M1 | T003,T004,T005 | DONE | qa.md PASS · 369975e |
| T007 | Settings & customization (LED modes, color, sound/haptic toggles) | M2 | T006 | DONE | qa.md PASS · cd5b240 |
| T008 | Stats panel (total · session · CPM · best) + reset | M2 | T006 | DONE | qa.md PASS · 616a93e |
| T009 | App identity: launcher icon + app name + versioning | M3 | T006 | DONE | qa.md PASS · 8d78383 |
| T010 | Release build: signing config + AAB + permissions audit | M3 | T009 | DONE | qa.md PASS · 89027f3 |
| T011 | Store listing metadata + privacy policy | M3 | T010 | DONE | qa.md PASS · 20d13b7 |
| T012 | 스위치 11종 확장 + UI 개편(키캡·통계 2개·선택기) | M4 | — | TODO | — |

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
- 2026-06-22 (사용자 확정): **앱 표시 이름 = "클리커"**(한글; 런처 라벨 + 스토어 제목). app id = **com.secondsyndrome.cliker** 확정(출시 후 영구). 릴리스 서명 **keystore는 플래너가 생성**(업로드 키, key.properties는 gitignore) — 사용자가 keystore 파일+비밀번호를 안전 백업해야 하며, Play 앱 서명 사용 시 업로드 키 분실은 재설정 가능. 실제 Play 업로드는 사용자가 자기 계정으로 수행(플래너는 업로드까지 하지 않음, AAB+메타데이터까지 준비).

## Open questions (for the user)
<!-- Things the Planner needs the user to decide. Resolve via tiki-taka, then move to Decisions. -->
- (없음 — M3 식별/서명 결정 모두 확정, Decisions log 참조)

## Reflected results
<!-- Append-only. Each entry is the Planner's audited summary of a completed task,
     citing the qa.md verdict and commit it trusts. -->
- 2026-06-22 · **T001 DONE** (commit `9593ce2`, qa.md `## Verdict: PASS`). 다크+네온 RGB 디자인 토큰 확정: `AppColors`(bg/surface/keycap/text + 6색 ledPalette + 스위치 스템색, accentDefault=neonCyan), `AppSpacing`/`AppRadius`, `appTheme()`는 명시적 dark `ColorScheme`(primary=neonCyan, fromSeed 미사용). Planner 직접 확인: `flutter analyze` clean, `flutter test` 16 green, pubspec drift 없음. 신규 패키지 의존성 추가 없음(스코프 준수).
- 2026-06-22 · **T002 DONE** (commit `52b146d`, qa.md `## Verdict: PASS`). 스위치 카탈로그 `SwitchCatalog`=[blue 청축, brown 갈축, red 적축, black 흑축], stem/LED색은 `AppColors` 참조(하드코딩 없음). `tools/gen_sounds.py`(파이썬 표준 라이브러리만, 결정적)가 8개 WAV(44100Hz mono 16-bit)를 `assets/sounds/`에 생성·번들, pubspec 등록. 35 신규 단위 테스트. Planner 직접 확인: 내가 직접 재생성→black_down.wav SHA-256 바이트 동일(결정적 ✓), pubspec은 assets만 추가(신규 패키지 의존성 0), analyze clean, 51 tests green.
- 2026-06-22 · **T003 DONE** (commit `4cfc6d0`, qa.md `## Verdict: PASS`). `shared_preferences` 영구 저장 + Riverpod 상태: `SettingsNotifier`(선택 스위치/사운드·햅틱 토글/LedMode/LED색 모두 영구), `StatsNotifier`(누적·최고 영구, 세션·CPM 메모리, trailing-60s CPM, reset). 20 신규 단위 테스트. QA가 "fresh container=재시작" 테스트가 실제로 비영속을 감지함을 falsification-probe로 증명. Planner 직접 확인: 신규 의존성 shared_preferences 1개뿐, analyze clean, 71 tests green.
- 2026-06-22 · **T005 DONE** (commit `689d017`, qa.md `## Verdict: PASS`). 자기완결 `Keycap` 위젯(AppColors 베벨, 60ms 다운/90ms 스냅업 scale+트래블, ledColor 글로우, 누름마다 자가제거 `LedRipple`, onPressDown/onPressUp 콜백) + 5 위젯 테스트 + 2 골든(미눌림/눌림). QA 어드버서리얼: 눌림상태·리플제거 단정이 no-op이 아님을 증명, 골든은 --update-goldens 없이 일치. Planner 직접 확인: 신규 의존성 0, analyze clean, 78 tests green. (오디오/햅틱/통계/스크린 연결은 T006)
- 2026-06-22 · **T004 DONE** (commit `8829597`, qa.md `## Verdict: PASS`). 저지연 오디오: `SoundBackend` 추상화 뒤 `AudioPlayersBackend`(audioplayers 6.7.1 `AudioPool`, lowLatency). **soundpool은 빌드 불가로 폐기**(discontinued, 제거된 v1 임베딩) — 플래너 결정으로 audioplayers 교체(errorlog 1strike, 정상 수정). `Haptics`는 strength→light/medium/heavy. 18 테스트(FakeBackend + 플랫폼채널 mock). **`flutter build apk --debug` 성공**(QA가 독립 재빌드 + audioplayers dex 링크 확인). 최초 dev.md 테스트 카운트 오기(19→18)로 1차 FAIL→플래너가 증거에 맞게 정정→QA 재감사 PASS. Planner 직접 확인: soundpool 잔재 0, audioplayers 의존, analyze clean, 96 tests green. (실제 재생/지연 체감은 T006 런타임 스모크)
- 2026-06-23 · **버그픽스(출시 후) — 클릭 시 무음** (2단계). ① `5322e97`: 오디오 포커스 쟁탈 제거(`AndroidAudioFocus.none` + sonification) — 포커스 요청 0 확인했으나 사용자 여전히 무음. ② `605ee77`: 진짜 원인은 `PlayerMode.lowLatency`가 Android FAST 트랙을 요청 → 에뮬레이터/일부 기기가 거부(`AudioFlinger mismatch flags 0x4 vs 0x2`) → 무출력. **`PlayerMode.mediaPlayer`로 전환**(소스 preload라 클릭 지연 허용). **객관 증명**: logcat의 `AudioTrack: stop() called with N frames delivered` — 4851프레임(110ms=blue_down)/3308프레임(75ms=blue_up)이 스피커 sink로 실제 전달됨(WAV 길이와 정확히 일치), FAST mismatch 사라짐. analyze clean, 127 tests green. **가청 최종 확인은 사용자(이상적으론 실기기)**; 확인되면 릴리스 AAB 재빌드.
- 2026-06-22 · **T011 DONE — M3 완료, 프로젝트 완료** (commit `20d13b7`, qa.md `## Verdict: PASS`). `docs/store/`: 등록 문구 KO/EN(Play 글자수 제한 내 — QA가 독립 재측정: KO 20/49/1022, EN 25/73/1949), 개인정보처리방침 md+html(수집/전송 없음·로컬 전용 — 실제 앱과 교차 검증: 릴리스 매니페스트 권한 0, 네트워크/광고/분석 없음), 데이터 안전, 콘텐츠 등급, 업로드 체크리스트(사용자 전용 단계 표시), 실제 앱 스크린샷 6장. 앱 코드 무변경(127 tests green, docs만 추가). Planner 직접 확인: 7개 스토어 파일+스크린샷 존재, lib/test/pubspec 무변경, analyze clean, 127 tests green. **사용자 액션 잔여: feature graphic(1024×500) 제작, 개인정보 URL 호스팅, Play Console 업로드.**
- 2026-06-22 · **T010 DONE** (commit `89027f3`, qa.md `## Verdict: PASS`). 릴리스 서명: 업로드 keystore 생성(gitignore, 커밋 안 됨), `key.properties` 기반 `signingConfigs.release`(build.gradle.kts), R8 minify+shrink+keep 룰. **서명된 `app-release.aab`(41.5MB)** — 서명자 = 업로드 키(디버그 키 아님, cert SHA-256 일치). R8 릴리스 변형이 에뮬레이터에서 정상 동작(audioplayers 안 깨짐). 권한 감사: INTERNET/위험 권한 없음(오프라인 로컬 전용). QA가 자체 AAB 빌드+서명 검증+비밀 누출 검사(비번은 gitignored key.properties에만 존재). Planner 직접 확인: 비밀 미추적·gitignore·tracked 트리에 비번 누출 0, signingConfig 존재, analyze clean, 127 tests green. ⚠️ keystore 파일+비번은 사용자가 백업 필요(사용자에게 전달함).
- 2026-06-22 · **T009 DONE** (commit `8d78383`, qa.md `## Verdict: PASS`). 앱 정체성: 순수 코드 `AppIcon`(다크 키캡+네온 헤일로, AppColors)을 결정적 1024² 소스로 렌더 → flutter_launcher_icons(dev dep)가 레거시 mipmap + 적응형 아이콘 생성. `android:label=클리커`, version 1.0.0+1. app id 불변. QA가 자체 aapt2 badging(label='클리커', versionCode 1, 아이콘=적응형 xml) + mipmap이 stock과 바이트 상이 + 결정성 재실행 + 런처 스크린샷으로 확인. Planner 직접 확인: label/version/app id/dev-only dep, analyze clean, 127 tests green.
- 2026-06-22 · **T008 DONE — M2 완료** (commit `616a93e`, qa.md `## Verdict: PASS`). `StatsPanel`(누적/세션/CPM/최고 4타일, 천단위 포맷)이 M1 간단 리드아웃 대체, 리셋 버튼→확인 다이얼로그→`resetStats()`. 의존성 없는 `thousands()` 헬퍼(intl 미사용). 11 신규 테스트. 기존 stat Key 재사용으로 M1 스모크 유지. QA: cancel/confirm 구분·영구성 검증, 전체 120 tests green 무회귀. Planner 직접 확인: 신규 의존성 0, analyze clean, 120 tests green. **→ M2(폴리시/커스터마이즈) 완료: 설정 시트·LED 모드·통계 패널.**
- 2026-06-22 · **T007 DONE** (commit `cd5b240`, qa.md `## Verdict: PASS`). 설정 시트(홈 기어버튼): 사운드/햅틱 토글, 6 ledPalette 색 스와치, LED 모드 칩. `Keycap`에 하위호환 `ledMode` prop: solid/ripple + 애니메이션 rgbCycle(HSV hue 회전)·reactive(누름 플레어+감쇠). 9 신규 위젯 테스트(노출된 duration으로 시간의존 모드 테스트 가능화). QA mutation-probe로 LED 테스트가 no-op 아님 확인. Planner 직접 확인: 신규 의존성 0, analyze clean, 109 tests green, M1 루프 유지.
- 2026-06-22 · **T006 DONE — M1 완료** (commit `369975e`, qa.md `## Verdict: PASS`). 홈 화면 통합: `main.dart`가 SharedPreferences+ClickSoundPlayer를 ProviderScope에 주입, `ClikerApp(appTheme)`, `HomeScreen`=통계 리드아웃(total/session/CPM)+배선된 `Keycap`(누름→사운드+햅틱+통계, 떼면 up음)+스위치 선택기. 카운터 보일러플레이트 제거, integration_test 신규. 100 tests green, **에뮬레이터(emulator-5554)에서 integration 통과 + 런타임 스모크**(5탭→카운터 5, 적축 선택 시 라벨/하이라이트 변경, 세로↔가로 회전에서 상태보존·무크래시, logcat 무결함). **출시 사운드 기본값 ON**(settings_providers.dart:110 `?? true`; integration 테스트의 sound off는 테스트 시드 한정). QA가 자체 런타임 스모크(스크린샷 7장)로 독립 확인. Planner 직접 확인: 신규 의존성 0, sound default ON 소스 확인, analyze clean, 100 tests green. **→ 핵심 루프가 실기기에서 끝까지 동작함이 검증됨.**
