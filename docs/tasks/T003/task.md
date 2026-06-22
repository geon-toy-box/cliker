---
task: T003
project: cliker
milestone: M1
created: 2026-06-22
status: TODO
tags: [toybox, task]
---

# T003 — Persistence + settings & stats state (Riverpod)

## Context
선택한 스위치·토글·LED 설정과 누적 통계가 앱을 껐다 켜도 유지돼야 한다(Definition of
shippable). 이 작업은 `shared_preferences` 기반 영구 저장과 그 위의 Riverpod 상태
(설정/통계)를 만든다. UI/오디오는 이 상태를 구독·갱신만 한다.

## Scope — what to build
- 의존성: `flutter pub add shared_preferences` (이 작업만 pubspec deps를 수정 — T004와 병렬 금지).
- `lib/persistence/settings_store.dart`
  - `final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('override in main'));`
    (main에서 `SharedPreferences.getInstance()` 결과로 override; 테스트는 `SharedPreferences.setMockInitialValues` 후 override)
- `lib/providers/settings_providers.dart`
  - `enum LedMode { ripple, solid, rgbCycle, reactive }`
  - `class Settings { final String selectedSwitchId; final bool soundEnabled; final bool hapticEnabled; final LedMode ledMode; final int ledColorArgb; }` (+`copyWith`, 값 동등성)
  - `class SettingsNotifier extends Notifier<Settings>` — `build()`에서 prefs 읽어 초기화(없으면 기본값:
    selectedSwitchId=`SwitchCatalog.defaultSwitch.id`(blue), soundEnabled=true, hapticEnabled=true,
    ledMode=`LedMode.ripple`, ledColorArgb=`AppColors.accentDefault.toARGB32()`).
    메서드: `selectSwitch(id)`, `setSound(bool)`, `setHaptic(bool)`, `setLedMode(LedMode)`, `setLedColor(int argb)` — 각각 상태 갱신 + prefs 저장.
  - `final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);`
- `lib/providers/stats_providers.dart`
  - `class Stats { final int totalClicks; final int sessionClicks; final int cpm; final int bestCpm; }`
  - `class StatsNotifier extends Notifier<Stats>` — `totalClicks`/`bestCpm`는 prefs에서 로드·저장, `sessionClicks`/`cpm`는 메모리(앱 재시작 시 0).
    - `void registerClick(DateTime now)` — totalClicks/sessionClicks +1, 최근 60초 윈도우 타임스탬프로 `cpm` 재계산, `bestCpm = max(bestCpm, cpm)` 저장. (now 주입으로 테스트 결정적)
    - `void resetStats()` — total/session/cpm/best 0으로 + prefs 반영.
  - `final statsProvider = NotifierProvider<StatsNotifier, Stats>(StatsNotifier.new);`

## Out of scope
- 오디오 재생/soundpool (T004), 위젯/스크린/실제 클릭 와이어링 (T005/T006).
- LED 모드의 시각적 구현(T005/T007) — 여기선 설정 값만 저장.

## Acceptance criteria (QA verifies each)
- [ ] AC1: 빈 prefs(`setMockInitialValues({})`)에서 `SettingsNotifier`가 위 기본값을 반환 — 단위 테스트.
- [ ] AC2: `selectSwitch/setSound/setHaptic/setLedMode/setLedColor` 호출 후 값이 prefs에 저장되어, 새 `ProviderContainer`로 다시 빌드해도 값이 유지 — 단위 테스트.
- [ ] AC3: `registerClick`가 totalClicks·sessionClicks를 +1 하고, totalClicks는 재빌드(새 컨테이너) 후에도 유지, sessionClicks는 새 컨테이너에서 0 — 단위 테스트(mock prefs).
- [ ] AC4: 주입한 타임스탬프 시퀀스에 대해 `cpm`이 직전 60초 윈도우 내 클릭 수를 반영하고 `bestCpm`이 관측 최댓값으로 갱신·유지 — 단위 테스트.
- [ ] AC5: `resetStats()`가 total/session/cpm/best를 0으로 만들고 prefs에 반영(재빌드 후 total=0, best=0) — 단위 테스트.
- [ ] AC6: `flutter analyze` → "No issues found!", `dart format --set-exit-if-changed .` → 0, `flutter pub get` 해상 OK.

## Test plan — which pyramid layers apply
- Format / Analyze: required
- Unit: required (AC1–AC5; `flutter_test` + `SharedPreferences.setMockInitialValues` + `ProviderContainer`)
- Widget: N/A: 위젯 없음
- Golden: N/A
- Integration: N/A: 플로우/스크린 없음
- Build: N/A: 엔트리포인트 변경 없음 (프로바이더는 단위 테스트로 검증)
- Runtime smoke: N/A: 실행 화면 없음 (T006에서 통합)

## Evidence
- Dev evidence:  docs/tasks/T003/evidence/dev/
- QA evidence:   docs/tasks/T003/evidence/qa/
