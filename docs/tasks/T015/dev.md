---
task: T015
role: dev
date: 2026-06-25
---

# T015 dev notes — 동적 타건 (딸깍 ↔ 따~알~깍)

## What changed
- **합성기** (`tools/gen_sounds.py`): `COMPONENT_PARAMS`(onset/click/bottom) +
  2단계 생성 — ① down/up 전체(기존 RNG 순서/바이트 보존, **절대 변경 금지** 블록)
  → ② onset/click/bottom. click은 clicky·tactile만(linear 생략). 총 **57 WAV**.
- **도메인** (`switch_type.dart`): `onsetAsset`/`bottomAsset`는 `id`에서, `clickAsset`는
  `kind != linear`일 때만 → 카탈로그와 생성 자산이 구조적으로 절대 어긋나지 않음.
  `soundAssets`가 로딩/테스트의 단일 출처.
- **엔진** (`dynamic_click_engine.dart`, 신규): onset 즉시 재생 + click@clickDelay,
  bottom@bottomDelay 타이머. `spread = force?null:intensity : 0.5*intensity+0.5*(1-force)`,
  지연/음량을 spread/force로 보간. `pressUp`: bottom 발화=따~알~깍 / click만=따알 /
  아무것도 안 = 빠른 탭 → 크리스프 `down`. `pressDown` 재진입·`dispose`에서 타이머 취소.
  상수 전부 `static const` 노출(온디바이스 튜닝/테스트용).
- **press_force.dart**(신규): pressureMin==pressureMax(센서 없음)→null, 아니면 (0,1) 정규화.
- **재생** (`click_sound_player.dart`): playOnset/Click/Bottom + init이 soundAssets 전부 로드.
  playClick은 linear(null)에서 no-op. mediaPlayer/AudioFocus.none **불변**.
- **설정** (`settings_providers.dart`): dynamicClickEnabled(true)/Intensity(0.5) 추가·영구·클램프.
- **UI** (`keycap.dart` Listener로 force 포착 후 onPressDown(force); `settings_sheet.dart`
  토글+슬라이더, 시트를 SingleChildScrollView로(컨트롤 증가로 오버플로 방지);
  `home_screen.dart` 동적/classic 분기).

## Verification (local)
- `python3 tools/gen_sounds.py` ×2 → 전체 트리 체크섬 동일(결정적). blue_down/black_down/
  magnetic_up SHA-256 = 변경 전과 동일(기존 바이트 보존 증명). onset13/bottom13/click5=57.
- `flutter analyze` → **No issues found!**
- `dart format --set-exit-if-changed lib test` → clean.
- `flutter test` → **327 passed** (baseline 207 → +120). 신규: dynamic_click_engine_test
  (fakeAsync로 4 시나리오+힘 음량+robustness), press_force_test, click_sound_player 스템,
  settings 동적 필드, settings_sheet 컨트롤, smoke 동적/classic 2갈래.
- 기존 press-wiring/haptic 테스트는 classic 경로(dynamicClickEnabled=false 시드)로 고정해
  계약 보존 + 동적 기본은 신규 테스트로 커버.

## Known follow-ups
- 가청 분해음 체감(특히 빠른 탭의 down 지연감)은 **온디바이스/웹에서 사용자 튜닝** 필요
  — 엔진 ms 상수는 노출되어 있어 코드 한 곳에서 조정 가능.
- 접촉면적(size) 보조 신호, 햅틱도 단계별로 쪼개는 것은 후속 후보.
