---
task: T010
project: cliker
milestone: M3
created: 2026-06-22
status: TODO
tags: [toybox, task]
---

# T010 — Release build: signing config + AAB + permissions audit

## Context
Play Console는 **서명된 AAB**(Android App Bundle)를 요구한다. 이 작업은 업로드용
keystore를 생성하고, 릴리스 서명 설정을 build.gradle에 넣고, 권한을 점검한 뒤,
`flutter build appbundle --release`로 서명된 출시 산출물을 만든다. 사용자 확정:
keystore는 **플래너 측에서 생성**(업로드 키), 비밀번호/파일은 사용자가 백업.

## Scope — what to build
- 업로드 keystore 생성(커밋 금지):
  - `keytool -genkeypair -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048
    -validity 10000 -alias upload -dname "CN=cliker, O=geontoybox, C=KR"`로 생성,
    강력한 랜덤 storepass/keypass 사용.
  - `android/key.properties` 작성(storePassword/keyPassword/keyAlias=upload/storeFile=upload-keystore.jks).
  - `.gitignore`에 `android/key.properties`와 `**/upload-keystore.jks`(및 `*.jks`) 추가 — **절대 커밋 금지**.
- 릴리스 서명 설정: `android/app/build.gradle(.kts)`에서 key.properties 로드 → `signingConfigs.release` 정의 →
  `buildTypes.release.signingConfig = release`. (디버그 키로 릴리스 서명하던 기본값 제거.)
- R8/리소스 축소: `isMinifyEnabled=true`, `isShrinkResources=true` (릴리스). 필요한 keep 룰
  (`android/app/proguard-rules.pro`)을 추가하되, **릴리스 빌드가 실제로 실행되는지** 에뮬레이터로 검증해
  난독화로 audioplayers/Flutter 플러그인이 깨지지 않음을 확인. (깨지면 keep 룰로 해결, 못 풀면 minify 비활성화로 문서화 후 보고.)
- 권한 점검: 최종 릴리스 `AndroidManifest.xml`의 권한을 감사 — 햅틱/로컬 오디오/오프라인 동작에
  **필요한 최소 권한만** 남긴다(불필요한 INTERNET 등 제거; 필요 권한과 사유를 문서화).
- 산출물: `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab` 생성·**서명 확인**.

## Out of scope
- 실제 Play Console 업로드(사용자가 자기 계정으로 수행). 스토어 문구/스크린샷(T011).
- keystore 파일/비밀번호의 저장소 커밋(금지).

## Acceptance criteria (QA verifies each)
- [ ] AC1: `android/key.properties`와 keystore가 존재하고 **gitignore되어 추적되지 않음**(`git status`/`git ls-files`로 미추적 확인) — 비밀이 저장소에 들어가지 않음.
- [ ] AC2: `android/app/build.gradle*`에 key.properties 기반 `signingConfigs.release`가 있고 `release` 빌드타입이 이를 사용(디버그 서명 아님).
- [ ] AC3: `flutter build appbundle --release` 성공 → `app-release.aab` 생성. AAB(또는 그 안의 APK)가 **업로드 키로 서명**되어 있음을 검증(`jarsigner -verify` 또는 bundletool/apksigner; 서명자 = upload alias) — 증거 첨부.
- [ ] AC4: 권한 감사 — 릴리스 매니페스트 권한 목록을 추출하고, 각 권한의 필요성(또는 불필요로 제거)을 문서화. 불필요한 권한 없음.
- [ ] AC5: 릴리스 변형이 실기기에서 동작 — 에뮬레이터에 release(또는 release AAB→apks) 설치·실행해 핵심 루프(탭→카운터/효과)와 크래시 없음 확인(R8 난독화 후에도). 스크린샷+logcat.
- [ ] AC6: `flutter analyze` → "No issues found!", `dart format --set-exit-if-changed .` → 0, `flutter test` green.

## Test plan — which pyramid layers apply
- Format / Analyze: required
- Unit/Widget: N/A: 빌드/서명/권한 구성 (앱 로직 변경 없음)
- Golden: N/A
- Integration: N/A (런타임은 아래 스모크로)
- Build: required (AC3 release AAB가 핵심 산출물)
- Runtime smoke: required (AC5 — R8 릴리스 변형이 실제로 도는지)

## Evidence
- Dev evidence:  docs/tasks/T010/evidence/dev/
- QA evidence:   docs/tasks/T010/evidence/qa/
