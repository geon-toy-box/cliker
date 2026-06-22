---
task: T008
project: cliker
milestone: M2
created: 2026-06-22
status: TODO
tags: [toybox, task]
---

# T008 — Stats panel (total · session · CPM · best) + reset

## Context
"누른 만큼 쌓이는 기록"이 스트레스 해소의 동기 요소다. T003의 `statsProvider`가 이미
누적/세션/CPM/최고CPM을 들고 있고 reset도 있다. 이 작업은 그것을 제대로 보여주는
통계 패널과 리셋(확인 다이얼로그)을 더한다. M1 홈의 간단 리드아웃을 풍부한 패널로 확장.

## Scope — what to build
- `lib/widgets/stats_panel.dart` (또는 screens/) — `statsProvider` 구독:
  - 누적 클릭(totalClicks), 이번 세션(sessionClicks), 현재 CPM(cpm), 최고 CPM(bestCpm)을
    라벨/아이콘과 함께 카드형으로 표시. 큰 숫자는 천단위 구분.
  - 값은 실시간 갱신(누를 때마다).
  - 리셋 버튼 → 확인 다이얼로그("정말 초기화?") → 확인 시 `statsProvider.resetStats()`.
- HomeScreen 통합: M1의 간단 리드아웃 자리를 이 패널로 대체하거나, 패널 진입점(예: 상단 통계 영역 탭/펼치기)을 둔다. 핵심 키캡 인터랙션은 그대로 유지.
- 모든 색/간격은 `AppColors`/`AppSpacing`에서.

## Out of scope
- 설정/LED/사운드 토글 (T007). 통계 로직 자체(이미 T003에서 구현·검증) — 표시/리셋 UI만.
- 그래프/히스토리 차트(스코프 밖; 단순 수치 패널).

## Acceptance criteria (QA verifies each)
- [ ] AC1: 통계 패널이 total/session/CPM/best 4개 값을 라벨과 함께 표시(각 값에 findable Key) — 위젯 테스트.
- [ ] AC2: 키캡(또는 테스트용 트리거)로 클릭 등록 시 total·session 표시가 증가하고, 천단위 구분 포맷이 적용(예: 1,234) — 위젯 테스트.
- [ ] AC3: 리셋 버튼 탭 → 확인 다이얼로그 표시, 취소 시 값 유지, 확인 시 total/session/cpm/best가 0으로 표시되고 `statsProvider`가 reset됨(영구) — 위젯 테스트.
- [ ] AC4: `flutter analyze` → "No issues found!", `dart format --set-exit-if-changed .` → 0, `flutter test` green.
- [ ] AC5: `flutter build apk --debug` 성공.

## Test plan — which pyramid layers apply
- Format / Analyze: required
- Unit: N/A: 통계 로직은 T003에서 단위 검증; 여기선 표시/포맷 (포맷 헬퍼가 분리되면 단위 1개 권장)
- Widget: required (AC1–AC3, mock prefs + ProviderScope)
- Golden: 선택 — 통계 패널 1컷 골든(고정 값) 권장 (N/A 시 사유)
- Integration: N/A: 표시 위주, 엔드투엔드는 T006
- Build: required (AC5)
- Runtime smoke: 권장 — 에뮬레이터에서 누적 증가 + 리셋 동작 1회 확인(스크린샷)

## Evidence
- Dev evidence:  docs/tasks/T008/evidence/dev/
- QA evidence:   docs/tasks/T008/evidence/qa/
