---
task: T004
project: cliker
milestone: M1
created: 2026-06-22
status: TODO
tags: [toybox, task]
---

# T004 — Audio service (low-latency) + haptics service

## Context
"좋다"의 기준은 탭 → 피드백 지연이 체감되지 않는 것. 이 작업은 스위치 타건음을
**저지연**으로 재생하는 오디오 서비스(soundpool 기반)와 진동 햅틱 서비스를 만든다.
soundpool은 cliker 첫 네이티브 플러그인이므로, 이 작업이 **Android 디버그 빌드 스모크**로
플러그인이 Gradle 빌드에 실제로 통합됨을 증명한다.

## Scope — what to build
- 의존성: `flutter pub add soundpool` (이 작업만 pubspec deps 수정 — T003과 병렬 금지, T003 VERIFIED 후 디스패치).
- `lib/audio/click_sound_player.dart`
  - 테스트 가능하도록 백엔드 추상화:
    `abstract class SoundBackend { Future<int> load(String asset); Future<void> play(int soundId, {double volume}); Future<void> dispose(); }`
  - `class SoundpoolBackend implements SoundBackend` — soundpool로 asset 로드/재생(`rootBundle`/`Soundpool` API).
  - `class ClickSoundPlayer` — 생성자에 `SoundBackend` 주입.
    - `Future<void> init()` — `SwitchCatalog.all`의 down/up 자산 전부(8개) preload → `Map<String,int>`(assetPath→soundId).
    - `Future<void> playDown(SwitchType s, {double volume})`, `playUp(SwitchType s, {double volume})` — 해당 asset의 soundId로 backend.play.
    - `bool muted` (기본 false) — true면 play 호출을 무시.
    - `Future<void> dispose()`.
  - `final clickSoundPlayerProvider = Provider<ClickSoundPlayer>(...)`(SoundpoolBackend로 구성; main에서 init).
- `lib/services/haptics.dart`
  - `class Haptics { Future<void> click(double strength); }` — strength 버킷으로 `HapticFeedback` 매핑:
    `strength < 0.5` → `selectionClick()`/`lightImpact()`, `0.5–0.8` → `mediumImpact()`, `> 0.8` → `heavyImpact()`.
    `bool enabled`(기본 true) — false면 호출 무시.
  - `final hapticsProvider = Provider<Haptics>(...)`.

## Out of scope
- 위젯/스크린/실제 탭 와이어링 (T005/T006) — 서비스는 호출 가능한 API만 제공.
- 설정값(soundEnabled/hapticEnabled) 연결은 T006에서 (여기선 muted/enabled 플래그만 노출).
- 패키지 스왑 금지: soundpool 빌드가 실패하면 **임의로 다른 오디오 패키지로 교체하지 말고** BLOCKED로 전체 에러를 보고 — 폴백(audioplayers low-latency)은 플래너가 결정.

## Acceptance criteria (QA verifies each)
- [ ] AC1: `ClickSoundPlayer.init()`가 주입한 FakeBackend로 `SwitchCatalog.all`의 down/up 자산 정확히 8개를 올바른 경로로 load — 단위 테스트.
- [ ] AC2: `playDown(blue)`/`playUp(blue)`가 각각 `blue_down.wav`/`blue_up.wav`의 soundId로 `backend.play`를 호출(다른 스위치도 1종 검증) — 단위 테스트.
- [ ] AC3: `muted=true`일 때 `playDown/playUp`가 `backend.play`를 호출하지 않음 — 단위 테스트.
- [ ] AC4: `Haptics.click(strength)`가 strength 버킷에 맞는 `HapticFeedback` 플랫폼 메서드를 호출하고, `enabled=false`면 어떤 플랫폼 호출도 하지 않음 — 위젯 테스트(`TestDefaultBinaryMessenger`로 `SystemChannels.platform` 호출 캡처).
- [ ] AC5: `flutter build apk --debug`가 soundpool 포함 상태로 성공(Gradle 빌드 green) — 증거에 빌드 마지막 출력 첨부. (실패 시 BLOCKED 보고)
- [ ] AC6: `flutter analyze` → "No issues found!", `dart format --set-exit-if-changed .` → 0.

## Test plan — which pyramid layers apply
- Format / Analyze: required
- Unit: required (AC1–AC3, FakeBackend로 매핑/뮤트 검증)
- Widget: required (AC4 햅틱 플랫폼 채널 캡처)
- Golden: N/A: 렌더 표면 없음
- Integration: N/A: 화면 없음 (실 오디오 체감은 T006 런타임 스모크)
- Build: required (AC5 — soundpool 네이티브 통합 증명, debug apk)
- Runtime smoke: N/A: 실행 화면 없음 (T006에서 실제 재생 스모크)

## Planner amendment (2026-06-22) — audio package: soundpool → audioplayers
원안의 **soundpool**는 인프라적으로 빌드 불가(2.4.1 최신·discontinued, 제거된 v1
Android 임베딩 `PluginRegistry.Registrar` 사용 → `:soundpool:compileDebugKotlin`
실패, Flutter 3.41.7). 플래너 결정으로 저지연 백엔드를 **audioplayers**(`AudioPool`)로
교체한다. 다음을 제외한 스코프·AC는 그대로 유지:
- `SoundBackend` 추상화/인터페이스, `ClickSoundPlayer`, `Haptics`, 두 프로바이더의
  형태(shape), 모든 단위/위젯 테스트는 **불변**(백엔드 교체에 영향받지 않음).
- `SoundpoolBackend` 대신 `AudioPlayersBackend implements SoundBackend`를 구현
  (asset당 `AudioPool` 생성, `play`=`pool.start(volume:)`). pubspec: soundpool 제거,
  `audioplayers` 추가.
- AC5의 빌드 스모크는 **audioplayers** 통합 기준으로 `flutter build apk --debug` 성공이어야 함.
- audioplayers `AssetSource`의 prefix 주의: 등록 경로 `assets/sounds/x.wav`에 대해
  `AssetSource`는 'assets/'를 자동 prefix하므로 `sounds/x.wav`로 넘긴다(또는 동등 처리).
  실제 재생/asset 로드 검증은 T006 런타임 스모크에서.

## Evidence
- Dev evidence:  docs/tasks/T004/evidence/dev/
- QA evidence:   docs/tasks/T004/evidence/qa/
