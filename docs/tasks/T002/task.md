---
task: T002
project: cliker
milestone: M1
created: 2026-06-22
status: TODO
tags: [toybox, task]
---

# T002 — Switch domain catalog + synthesized switch sound assets

## Context
cliker의 정체성은 "여러 기계식 스위치 음색을 골라 누른다"이다. 이 작업은 (1) 스위치
카탈로그 도메인 모델과 (2) 각 스위치의 타건음(WAV) 자산을 **합성(synthesized)** 으로
생성한다. 저작권/라이선스 리스크를 피하려고 외부 음원을 받지 않고, 커밋된 파이썬
스크립트가 결정적(deterministic)으로 음을 만들어 번들한다. 이후 T004(오디오 서비스)가
이 자산을 저지연 재생한다.

## Scope — what to build
- `lib/domain/switch_type.dart`
  - `class SwitchType { final String id; final String nameKo; final String nameEn;
    final String description; final Color stemColor; final Color defaultLed;
    final String downAsset; final String upAsset; final double hapticStrength; ... }`
    (const 생성자, `==`/`hashCode`는 `id` 기준 또는 equatable 수동 구현)
  - `class SwitchCatalog`:
    - `static const List<SwitchType> all` = `[blue, brown, red, black]` (이 순서)
      - blue: id `blue`, nameKo `청축`, nameEn `Blue`, stem `AppColors.switchBlue`, defaultLed `AppColors.neonCyan`, hapticStrength `1.0`, assets `assets/sounds/blue_down.wav`/`blue_up.wav`, description: 또렷한 "딸깍" 클릭음(키보드 ASMR 대표).
      - brown: id `brown`, nameKo `갈축`, nameEn `Brown`, stem `AppColors.switchBrown`, defaultLed `AppColors.neonOrange`, hapticStrength `0.7`, 부드러운 텍타일 범프 "톡".
      - red: id `red`, nameKo `적축`, nameEn `Red`, stem `AppColors.switchRed`, defaultLed `AppColors.neonMagenta`, hapticStrength `0.45`, 매끈하고 조용한 리니어 "톡".
      - black: id `black`, nameKo `흑축`, nameEn `Black`, stem `AppColors.switchBlack`, defaultLed `AppColors.neonGreen`, hapticStrength `0.6`, 묵직하고 깊은 리니어.
    - `static SwitchType byId(String id)` (없으면 `defaultSwitch` 반환), `static const SwitchType defaultSwitch = blue`(=`all.first`).
- `tools/gen_sounds.py` — 결정적 합성 스크립트 (Python **표준 라이브러리만**: `wave, struct, math, random`; 서드파티/`numpy` 금지):
  - 각 스위치마다 `<id>_down.wav`, `<id>_up.wav` 생성 → `assets/sounds/`에 출력.
  - 형식: 44100 Hz, **mono, 16-bit PCM**, 길이 60–160ms.
  - 합성 구성: 짧은 노이즈 트랜지언트(클릭) × 빠른 지수 감쇠 엔벨로프 + 감쇠 사인파 "바디" 공명. 스위치별 파라미터:
    blue=밝고 날카로운 더블 틱(클릭), brown=중역 텍타일 톡, red=조용한 리니어, black=저역 묵직.
    down은 up보다 약간 크고 낮게(릴리스음은 더 짧고 높게).
  - **결정적**: 고정 시드(`random.seed(...)`)로 재실행 시 바이트 동일.
  - 스크립트 상단에 "재생성 방법: `python3 tools/gen_sounds.py`" 주석.
- `pubspec.yaml` — `flutter: assets:`에 `assets/sounds/` 등록. (의존성 패키지 추가 없음 — 자산만)
- 생성된 `assets/sounds/*.wav` 8개 파일을 커밋.

## Out of scope
- 오디오 재생/햅틱 (T004), 위젯/스크린 (T005/T006), 영구 저장 (T003).
- 신규 pub 패키지 의존성 추가 금지(자산 등록만).

## Acceptance criteria (QA verifies each)
- [ ] AC1: `SwitchCatalog.all`가 `[blue,brown,red,black]` 4종을 이 순서로 노출, id 유일, 각 항목의 nameKo/nameEn/description 비어있지 않음, stemColor가 대응 `AppColors.switch*`와 일치, defaultLed가 `AppColors.ledPalette`에 포함, hapticStrength ∈ (0,1] — 단위 테스트.
- [ ] AC2: `byId('red')`가 red 반환, `byId('bogus')`가 `defaultSwitch`(blue) 반환, `defaultSwitch == all.first` — 단위 테스트.
- [ ] AC3: 모든 스위치의 down/up 자산 8개가 디스크에 실제 존재하고, 크기 > 1KB, 파싱 시 유효한 WAV(RIFF/WAVE, fmt: channels=1, sampleRate=44100, bitsPerSample=16) — 단위 테스트가 각 `downAsset`/`upAsset` 경로를 `File`로 열어 헤더 검증.
- [ ] AC4: `tools/gen_sounds.py`가 커밋되어 있고 표준 라이브러리만 사용. 재실행(`python3 tools/gen_sounds.py`) 후 `git status --porcelain assets/sounds`가 빈 출력(=바이트 동일, 결정적) — 증거에 명령/출력 첨부.
- [ ] AC5: `assets/sounds/`가 pubspec에 등록되고 `flutter pub get`이 깨끗이 해상 — 증거 첨부.
- [ ] AC6: `flutter analyze` → "No issues found!", `dart format --set-exit-if-changed .` → 0.

## Test plan — which pyramid layers apply
- Format / Analyze: required
- Unit: required (AC1 카탈로그, AC2 lookup, AC3 자산 WAV 헤더 검증)
- Widget: N/A: 위젯 없음
- Golden: N/A: 렌더 표면 없음
- Integration: N/A: 플로우 없음
- Build: N/A: 엔트리포인트 변경 없음 (자산 등록만; pub get 해상으로 충분)
- Runtime smoke: N/A: 실행 화면 없음 (재생은 T004)

## Evidence
- Dev evidence:  docs/tasks/T002/evidence/dev/
- QA evidence:   docs/tasks/T002/evidence/qa/
