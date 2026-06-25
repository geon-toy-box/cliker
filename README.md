# cliker · 클리커

**LED 기계식 키캡 클릭커 — 화면 속 키캡을 눌러 타건음·진동·LED로 스트레스를 푸는 피젯 토이.**

화면 중앙의 큼직한 기계식 키캡 하나를 누르면 진짜 키보드처럼 **타건음 + 진동 +
LED 빛 효과**가 터지고, 누른 만큼 **클릭 카운터/통계**가 쌓입니다. 청축·갈축·적축
등 13종의 스위치 음색을 골라 자기 취향의 타건감을 만들 수 있습니다.

- **플랫폼**: Android (주력) · Flutter Web (Vercel 배포)
- **스택**: Flutter · Riverpod · `shared_preferences` · `audioplayers`
- **오프라인 전용**: 네트워크/수집 없음, 권한은 진동만.

---

## 핵심 기능

### 🎚 동적 타건 — "딸깍" ↔ "따~알~깍"

실제 기계식 스위치의 한 번의 타건은 단일 소리가 아니라 행정(travel)을 따라
이어지는 **음향 이벤트의 연속**입니다. cliker는 이를 분해해서 누름 방식에 따라
다르게 들려줍니다:

| 단계 | 소리 | 정체 |
|------|------|------|
| **onset** | "따" | 다운스트로크 시작/프리트래블 접촉음 (작고 어둡게) |
| **click** | "알" | 액추에이션 클릭 — clicky=클릭자켓 스냅, tactile=부드러운 범프, **linear=없음** |
| **bottom** | "깍" | 바텀아웃 충격 (묵직한 무게) |

화면을 **빠르고 강하게** 누르면 셋이 거의 동시에 뭉쳐 또렷한 **"딸깍"**, **천천히/
약하게** 누르면 시간차로 벌어지며 **"따~알~깍"**으로 늘어집니다.

- **판정**: 누름 **지속시간**이 보편 기준(웹·모든 폰에서 동작) — 빠른 탭은 딸깍,
  길게 누르면 따~알~깍. 힘(`PointerEvent.pressure`)을 보고하는 기기에서는 누르는
  **세기**가 분해 정도와 음량을 추가로 강조합니다.
- **설정**: 설정 시트의 **동적 타건** 토글로 끄면 기존처럼 항상 단일 "딸깍". **강도**
  슬라이더로 분해 정도를 조절합니다.

엔진 로직은 [`lib/audio/dynamic_click_engine.dart`](lib/audio/dynamic_click_engine.dart),
누름 압력 정규화는 [`lib/audio/press_force.dart`](lib/audio/press_force.dart)에
있습니다.

### 🔊 스위치 13종

청축(blue)·갈축(brown)·적축(red)·흑축(black)·백축(white)·회축(gray)·클리어(clear)·
저소음 적축/흑축(silentRed/silentBlack)·스피드 은축(speedSilver)·진회축(darkGray)·
황축(yellow)·자석축(magnetic). 각 스위치는 `clicky / tactile / linear` 종류, 작동압,
소리세기, 느낌·추천용도 정보를 가집니다 ([`lib/domain/switch_type.dart`](lib/domain/switch_type.dart)).

### 💡 LED · 📊 통계 · 📳 햅틱

- LED: RGB 휠로 색을 고르고 리플 / 솔리드 / RGB 순환 / 반응형 모드 선택.
- 통계: 전체 클릭 수 + RPM, 리셋 가능.
- 햅틱: 스위치 세기에 맞춘 light / medium / heavy 임팩트.

모든 선택(스위치·LED·토글·강도)은 앱을 다시 켜도 유지됩니다.

---

## 사운드는 어떻게 만들어지나

저작권/라이선스 리스크를 피하려고 **외부 음원을 쓰지 않고** 모든 타건음을
파이썬 표준 라이브러리만으로 **합성**해 번들합니다
([`tools/gen_sounds.py`](tools/gen_sounds.py)). 노이즈 임팩트("딱/탁" 어택) + 감쇠
사인 공명 모드("탁"의 음색)를 가산 합성하며, 고정 시드라 **재실행해도 바이트 단위로
동일**합니다.

스위치 한 종당 클립:

- `<id>_down.wav` / `<id>_up.wav` — 빠른 탭의 뭉친 "딸깍" + 릴리스
- `<id>_onset.wav` / `<id>_bottom.wav` — 동적 분해용 "따" / "깍"
- `<id>_click.wav` — 액추에이션 "알" (clicky·tactile 5종만, linear은 없음)

→ 총 **57개** WAV (44100Hz mono 16-bit).

```bash
python3 tools/gen_sounds.py          # assets/sounds/ 재생성 (결정적)
```

---

## 개발

```bash
flutter pub get
flutter run                          # 기기/에뮬레이터에서 실행
flutter run -d chrome                # 웹에서 실행

flutter analyze                      # 정적 분석 (clean 유지)
flutter test                         # 단위·위젯 테스트
dart format lib test                 # 포맷

flutter build apk                    # Android APK
./tools/vercel_build.sh              # 웹 정적 빌드 (Vercel)
```

### 구조

```
lib/
  audio/          ClickSoundPlayer(저지연 풀) · DynamicClickEngine · press_force
  domain/         SwitchType · SwitchCatalog (13종)
  providers/      Settings(영구) · Stats (Riverpod)
  screens/        HomeScreen — 키캡 + 통계 + LED 휠 배선
  widgets/        Keycap · SwitchMenu · SettingsSheet · RgbWheel · …
tools/gen_sounds.py   결정적 타건음 합성기
docs/             planner(단일 진실원) · errorlog · tasks/
```

> 오디오 메모: 클릭 SFX는 `PlayerMode.mediaPlayer` + `AndroidAudioFocus.none`을
> 씁니다. `lowLatency`는 일부 기기에서 FAST 트랙 거부로 무출력, 포커스 요청은 겹치는
> 클립을 서로 끊습니다 (`docs/errorlog.md` 참고).
