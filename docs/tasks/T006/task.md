---
task: T006
project: cliker
milestone: M1
created: 2026-06-22
status: TODO
tags: [toybox, task]
---

# T006 — Home screen wiring (keycap + audio + haptics + stats + switch selector)

## Context
M1의 마지막 조각. T001–T005의 테마·도메인·상태·오디오/햅틱·키캡을 하나의 동작하는
화면으로 묶고, 보일러플레이트 main.dart를 교체한다. 완료되면 "키캡 탭 → 저지연 타건음 +
진동 + LED + 카운터 증가, 스위치 선택, 재시작 후 통계 유지"가 실기기에서 끝까지 동작한다.

## Scope — what to build
- `lib/main.dart` — `WidgetsFlutterBinding.ensureInitialized()` →
  `SharedPreferences.getInstance()` → `ClickSoundPlayer.init()` → `runApp(ProviderScope(overrides:[sharedPreferencesProvider.overrideWithValue(prefs)], child: ClikerApp()))`.
- `lib/app.dart` — `ClikerApp`: `MaterialApp(theme: appTheme(), home: HomeScreen(), debugShowCheckedModeBanner:false)`.
- `lib/screens/home_screen.dart` — `HomeScreen` (ConsumerWidget/StatefulConsumer):
  - 상단: 간단 통계 리드아웃 — 누적(total), 세션(session), CPM (T008이 풀 패널로 확장; 여기선 읽기 표시).
  - 중앙: `Keycap` 연결 —
    - `ledColor = Color(settings.ledColorArgb)`, `label = 선택 스위치.nameEn`.
    - `onPressDown`: soundEnabled면 `clickSoundPlayer.playDown(selected)`, hapticEnabled면 `haptics.click(selected.hapticStrength)`, 그리고 `statsProvider.registerClick(DateTime.now())`.
    - `onPressUp`: soundEnabled면 `clickSoundPlayer.playUp(selected)`.
  - 하단: 스위치 선택기 — `SwitchCatalog.all` 칩 가로 행(각 nameKo, stemColor 강조), 탭 시 `settings.selectSwitch(id)`, 선택 칩 하이라이트.
  - soundEnabled/hapticEnabled를 player.muted/haptics.enabled에 반영(또는 호출부 가드).
- `test/widget/smoke_widget_test.dart` — 기존 카운터 보일러플레이트 테스트를 새 앱에 맞게 교체.
- `integration_test/app_test.dart` — 엔드투엔드 스모크(아래 AC5).

## Out of scope
- 설정 화면/LED 모드 전환/색상 피커/사운드·햅틱 토글 UI (M2 T007) — 여기선 기본값으로 동작.
- 풀 통계 패널/리셋 UI (M2 T008).

## Acceptance criteria (QA verifies each)
- [ ] AC1: 콜드 스타트 시 HomeScreen이 중앙 Keycap, 통계 리드아웃(total/session/CPM), 스위치 선택 행(4종)을 표시 — 위젯 테스트(mock prefs + Fake `SoundBackend`로 프로바이더 override).
- [ ] AC2: Keycap 탭 시 total·session 카운터 UI가 증가(예: 3번 탭 → total '3' 표시) — 위젯 테스트.
- [ ] AC3: 스위치 칩(예: '적축') 탭 시 선택 상태가 바뀌고(하이라이트 + Keycap label 갱신) `settingsProvider.selectedSwitchId == 'red'` — 위젯 테스트.
- [ ] AC4: Keycap press-down 시 주입한 Fake가 `playDown` 호출 + `haptics.click` 호출 + `stats.registerClick` 반영을 기록(release 시 `playUp`) — 위젯 테스트(Fake 백엔드/햅틱 스파이).
- [ ] AC5: `integration_test/app_test.dart`가 에뮬레이터/기기에서: 앱 실행 → Keycap 5회 탭 → total 카운터 5 표시 → '적축' 선택 후 1회 탭, 앱 생존(uncaught exception 없음) — `flutter test integration_test` 출력 증거.
- [ ] AC6: `flutter build apk --debug` 성공 + 런타임 스모크(에뮬레이터/기기): 콜드 스타트, 탭으로 카운터 증가, 스위치 변경, **화면 회전 시 크래시 없음** — 스크린샷/로그 증거.
- [ ] AC7: `flutter analyze` → "No issues found!", `dart format --set-exit-if-changed .` → 0, 전체 `flutter test` green(보일러플레이트 스모크 테스트 교체 포함).

## Test plan — which pyramid layers apply
- Format / Analyze: required
- Unit: N/A: 통합 화면 (로직은 T003에서 단위 검증됨) — 위젯/통합으로 커버
- Widget: required (AC1–AC4)
- Golden: N/A: 개별 시각 표면은 T005에서 골든 (화면 조립은 위젯 테스트로 충분)
- Integration: required (AC5 엔드투엔드)
- Build: required (AC6 debug apk)
- Runtime smoke: required (AC6 — 실기기/에뮬레이터, 카운터·스위치·회전)

## Evidence
- Dev evidence:  docs/tasks/T006/evidence/dev/
- QA evidence:   docs/tasks/T006/evidence/qa/
