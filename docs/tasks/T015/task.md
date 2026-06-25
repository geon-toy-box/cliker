---
task: T015
project: cliker
milestone: M6
created: 2026-06-25
status: IN_PROGRESS
tags: [toybox, task]
---

# T015 — 클릭음 고도화 + 동적 타건 (딸깍 ↔ 따~알~깍)

> 사용자 요청: "클릭음 고도화 및 화면 누르기 세기에 따른 딸깍 인지 따~알~깍인지
> 이런거 처리를 통해 고도화." README.md도 갱신.

## Context
한 번의 타건을 단일 클립으로만 재생하던 것을, 실제 스위치 행정의 음향 이벤트
(onset "따" → click "알" → bottom "깍")로 분해해 누름 방식에 따라 또렷한 "딸깍"
↔ 늘어진 "따~알~깍"으로 들려준다. M1~M5(핵심 루프·13종·MZ 리디자인) 위에 얹는
타건 피드백 고도화. 사용자 결정: 판정 = **지속시간(보편) + 힘(지원 기기 가중)**,
노출 = **항상 켬 + 설정 토글 + 강도 슬라이더**.

## Scope — what to build
- `tools/gen_sounds.py`: 스위치별 컴포넌트 스템 onset/bottom(전 13종) + click
  (clicky·tactile 5종)을 down/up **뒤에** 생성(기존 26개 바이트 보존) → 총 57 WAV.
- `SwitchType`: `onsetAsset`/`bottomAsset`/`clickAsset?`(linear=null)/`soundAssets` 파생 getter.
- `ClickSoundPlayer`: `playOnset`/`playClick`/`playBottom`, `init`이 전체 `soundAssets` 로드.
- `DynamicClickEngine`(신규): 누름→onset 즉시 + click/bottom를 spread(힘·강도) 기반
  지연으로 스케줄; 릴리스 시 빠른 탭=크리스프 down("딸깍"), 중간=onset+click, 풀=따~알~깍.
- `press_force.dart`(신규): pressure→[0,1] 정규화 또는 null(미지원).
- `Keycap`: Listener로 압력 포착, `onPressDown(double? force)`.
- `Settings`: `dynamicClickEnabled`(기본 true)+`dynamicClickIntensity`(0.5) 영구.
- `SettingsSheet`: 동적 타건 토글 + 강도 슬라이더(토글 off면 비활성), 시트 스크롤화.
- `HomeScreen`: 동적 엔진 배선(토글 off면 classic down/up).
- README.md 갱신.

## Out of scope
- 실기기 피드백 ms 미세 튜닝(엔진 상수는 노출만; 온디바이스 튜닝은 후속).
- 접촉면적(size) 기반 추가 신호, 새 스위치 추가.

## Acceptance criteria (QA verifies each)
- [ ] AC1: 합성기 재실행 시 기존 26 down/up WAV가 바이트 동일, 신규 31개 추가(총 57), 결정적.
- [ ] AC2: 엔진 — 빠른 탭=onset+down+up, 중간=onset+click+up, 풀=onset+click+bottom+up;
      linear은 click 없음; 타이머 누수/dispose 후 재생 없음(fakeAsync 테스트).
- [ ] AC3: 설정 — dynamicClickEnabled 기본 true·intensity 0.5, 토글/슬라이더 영구·클램프.
- [ ] AC4: 화면 — 동적 ON이면 down 시 onset 우선; 토글 OFF면 classic down/up 그대로.
- [ ] AC5: 오디오 제약 유지(mediaPlayer + AudioFocus.none), 웹 무압력=지속시간 경로.
- [ ] AC6: analyze clean · `dart format` clean · 테스트 그린 · README 갱신.

## Test plan
- Format / Analyze: required (clean)
- Unit: press_force, dynamic_click_engine(fakeAsync), click_sound_player 스템, settings 영구.
- Widget: keycap force 콜백, settings_sheet 토글/슬라이더, smoke 동적/classic 배선.
- Golden: keycap 골든 불변(Listener는 비시각) — 기존 골든 재사용.
- Integration: N/A(기기 전용; 사운드 off 스모크는 기존 유지).
- Build: required.
- Runtime smoke: 가청 분해음은 자동 QA 불가 → 사용자/실기기 확인 필요(errorlog 교훈).

## Evidence
- Dev evidence:  docs/tasks/T015/dev.md
- QA evidence:   docs/tasks/T015/qa.md (pending)
