---
task: T009
project: cliker
milestone: M3
created: 2026-06-22
status: TODO
tags: [toybox, task]
---

# T009 — App identity: launcher icon + app name (클리커) + versioning

## Context
Play 업로드 준비의 첫걸음 — 앱이 런처/스토어에서 "클리커"로 보이고, 기본 Flutter
아이콘이 아닌 cliker 정체성(다크 + 네온 RGB 키캡)의 런처 아이콘을 갖게 한다.
사용자 확정: 표시 이름 = **클리커**, app id = com.secondsyndrome.cliker(불변).

## Scope — what to build
- 앱 표시 이름 = **"클리커"**: `android/app/src/main/AndroidManifest.xml`의 `android:label`을 "클리커"로.
  (런처/설치 후 표시 이름. app id/패키지는 건드리지 않음.)
- 런처 아이콘 생성(기본 Flutter 아이콘 교체):
  - 아이콘 소스 이미지 1024×1024 PNG를 **앱의 비주얼로 합성**한다 — 외부 디자인 자산 없이:
    다크 배경 + 네온 글로우가 도는 키캡(또는 키캡 글리프)을 그리는 위젯을 만들고,
    골든/`RepaintBoundary.toImage` 방식으로 1024² PNG로 렌더해 `assets/icon/icon.png`(+ 어댑티브용
    foreground/background)로 저장하는 스크립트/테스트를 둔다.
  - `flutter_launcher_icons`(dev_dependency)로 안드로이드 아이콘(레거시 mipmap + **적응형 아이콘**
    foreground/background) 생성. `pubspec.yaml`(또는 flutter_launcher_icons.yaml)에 설정.
- 버전: `pubspec.yaml` `version: 1.0.0+1` 확인/설정(versionName 1.0.0 / versionCode 1).

## Out of scope
- 릴리스 서명/AAB/권한 (T010). 스토어 등록 문구/스크린샷 (T011). app id 변경.

## Acceptance criteria (QA verifies each)
- [ ] AC1: 설치/런처 표시 이름이 "클리커" — `android:label="클리커"`가 매니페스트에 있고, 디버그 빌드 설치 후 런처에 "클리커"로 표시(스크린샷).
- [ ] AC2: 런처 아이콘이 기본 Flutter 아이콘이 아니며 cliker 아이콘으로 교체됨 — `android/app/src/main/res/mipmap-*/`에 새 `ic_launcher` 리소스 + 적응형 아이콘 XML(`mipmap-anydpi-v26/ic_launcher.xml`) 존재, 기본 아이콘과 바이트 상이.
- [ ] AC3: 아이콘 소스 1024×1024 PNG가 커밋되어 있고(`assets/icon/…`), 그것을 만든 스크립트/테스트가 재현 가능(재실행 시 동일 결과) — 증거에 명령/해시.
- [ ] AC4: `version: 1.0.0+1` 설정됨.
- [ ] AC5: `flutter build apk --debug` 성공하고 새 아이콘/이름이 적용된 APK가 빌드됨. 에뮬레이터 런타임 스모크로 런처 아이콘+이름 확인(스크린샷).
- [ ] AC6: `flutter analyze` → "No issues found!", `dart format --set-exit-if-changed .` → 0, `flutter test` green(아이콘 렌더 테스트 포함, 기존 테스트 무회귀).

## Test plan — which pyramid layers apply
- Format / Analyze: required
- Unit: N/A: 아이콘/이름은 리소스/설정 (렌더 스크립트는 위젯/골든 성격)
- Widget/Golden: 아이콘 소스 렌더 1컷(고정 결과) 권장
- Integration: N/A
- Build: required (AC5)
- Runtime smoke: required (AC1/AC2/AC5 — 런처 아이콘·이름 육안 확인 스크린샷)

## Evidence
- Dev evidence:  docs/tasks/T009/evidence/dev/
- QA evidence:   docs/tasks/T009/evidence/qa/
