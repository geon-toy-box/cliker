# Google Play 업로드 체크리스트 — 클리커 (cliker)

> 서명된 AAB(T010)와 이 폴더의 자료로 Play Console 등록을 끝내기 위한 단계별 체크리스트.
> 각 항목은 그 자료가 **어디서 오는지**(산출물 경로/출처)를 가리킨다.
> 🧑 = **사용자가 직접 해야 하는 단계**(계정/업로드/호스팅 등 자동화 불가).
> 📄 = 이 저장소에 준비된 자료를 복사-붙여넣기/업로드하면 되는 단계.

앱 기본 정보 (참고):
- 표시명: **클리커** (영문 부제 cliker)
- 패키지(앱 ID): **com.secondsyndrome.cliker** (android/app/build.gradle.kts:38)
- 버전: **1.0.0 (+1)** → versionName 1.0.0 / versionCode 1 (pubspec.yaml:19)
- 성격: 완전 오프라인 · 개인정보 무수집 · 광고/분석 없음

---

## A. 사전 준비 (계정·앱 생성) — 🧑 사용자

- [ ] 🧑 Google Play 개발자 계정 등록(최초 1회, 등록비 결제 필요)
- [ ] 🧑 Play Console에서 새 앱 만들기 → 앱 이름 "클리커", 기본 언어 한국어,
      앱/게임 = "앱", 무료/유료 = "무료" 선택

## B. 앱 번들 업로드 (AAB) — 🧑 사용자 (자료는 준비됨)

- [ ] 🧑 프로덕션(또는 비공개 테스트) 트랙에 **서명된 AAB** 업로드
  - 산출물: `build/app/outputs/bundle/release/app-release.aab` (T010 산출물, 약 40MB,
    업로드 키로 서명됨 — T010 dev.md/qa.md 참조)
  - ⚠️ 업로드 키스토어(`android/upload-keystore.jks`)와 비밀번호(`android/key.properties`)는
    **git에 없으며 사용자가 안전하게 백업**해야 함(분실 시 동일 키로 업데이트 불가).
    Play 앱 서명(Play App Signing)을 사용하면 배포 키는 Google이 관리.

## C. 스토어 등록정보 (텍스트) — 📄 자료 준비됨 / 🧑 입력은 사용자

- [ ] 📄 한국어 제목·짧은 설명·자세한 설명 입력
  - 출처: `docs/store/listing-ko.md` (글자수 검증: 제목 20 / 짧은 49 / 자세한 1022,
    모두 한도 30/80/4000 이내)
- [ ] 📄 영어(en-US) 등록정보 추가(선택, 글로벌 노출용)
  - 출처: `docs/store/listing-en.md` (제목 25 / 짧은 73 / 자세한 1949, 한도 이내)
- [ ] 📄 앱 카테고리 선택 — 권장: **엔터테인먼트**(대안: 도구). 근거: listing-*.md 참조
- [ ] 📄 연락처 이메일: **geon@2ndsyndrome.com**

## D. 그래픽 자산 — 📄 일부 준비됨 / 🧑 일부 필요

- [ ] 📄 앱 아이콘 512×512 (Play 등록정보용 고해상도 아이콘)
  - 출처: `assets/icon/icon.png` (1024×1024 소스, T009 산출물 — 512로 리사이즈해 사용).
    런처 아이콘 자체는 AAB에 이미 포함됨(android/app/src/main/res/mipmap-*).
- [ ] 📄 휴대전화 스크린샷(최소 2장, 권장 4~8장)
  - 출처: `docs/store/screenshots/` — 실제 앱 캡처 6장:
    - `01-home-keycap.png` — 홈/키캡(청축, 시안 LED)
    - `02-tap-counter.png` — 탭 순간 LED 리플 + 카운터 증가
    - `03-settings-sheet.png` — 설정 시트(사운드/햅틱, LED 색·모드)
    - `04-switch-selection.png` — 스위치 선택(적축, 라벨 "Red")
    - `05-led-customize.png` — LED 색(마젠타)+모드(솔리드) 선택
    - `06-home-magenta-solid.png` — 마젠타 솔리드 LED 적용 홈
  - ⚠️ 캡처 해상도 320×640(에뮬레이터). Play 최소 요건(각 변 ≥320px)은 충족하나,
    고품질 등록을 원하면 🧑 더 높은 해상도 기기/에뮬레이터에서 재캡처 권장.
- [ ] 🧑 그래픽 이미지(피처 그래픽) 1024×500 1장 — **미준비**, 사용자가 제작 필요
      (Play 필수 자산). 앱 아이콘/네온 키캡 모티브 활용 권장.

## E. 앱 콘텐츠 (정책 양식) — 📄 답변 준비됨 / 🧑 제출은 사용자

- [ ] 🧑📄 개인정보처리방침 URL 입력
  - 자료: `docs/store/privacy-policy.html` (브라우저에서 바로 열리는 완성본)
  - 🧑 사용자가 공개 URL로 **호스팅**해야 함(예: GitHub Pages). 그 URL을 Play Console
    "개인정보처리방침" 필드에 입력. (`privacy-policy.md`는 동일 내용의 마크다운 사본.)
- [ ] 📄 데이터 보안(Data safety) 양식 작성 — 수집/공유 없음, 로컬 전용
  - 출처: `docs/store/data-safety.md`
- [ ] 📄 콘텐츠 등급(IARC) 설문 — 모두 "아니요" → 전체이용가 예상
  - 출처: `docs/store/content-rating.md`
- [ ] 🧑 대상 연령층 / 광고 포함 여부: **광고 없음** 선택
- [ ] 🧑 뉴스 앱 아님 / 코로나19 앱 아님 / 정부 앱 아님 등 표준 선언 응답

## F. 가격 및 배포 — 🧑 사용자

- [ ] 🧑 가격 = **무료(Free)** 설정 (인앱 결제 없음)
- [ ] 🧑 배포 국가 선택 — 권장: 대한민국 포함 전체 국가(앱이 오프라인·로컬이라 지역 제약 없음)
- [ ] 🧑 콘텐츠 가이드라인 / 미국 수출법 준수 동의

## G. 출시 — 🧑 사용자

- [ ] 🧑 내부/비공개 테스트로 먼저 설치·동작 확인 후 프로덕션으로 승급 권장
- [ ] 🧑 검토 제출 → Google 심사 통과 후 게시

---

### 자료 매핑 요약 (어디서 오는가)

| Play 항목 | 산출물/출처 | 준비 상태 |
|-----------|-------------|-----------|
| 서명된 AAB | `build/app/outputs/bundle/release/app-release.aab` (T010) | 준비됨(사용자 업로드) |
| 런처 아이콘 | AAB 내 mipmap (T009) | 포함됨 |
| 등록용 512 아이콘 | `assets/icon/icon.png`(1024, 리사이즈) | 준비됨 |
| 한국어 문구 | `docs/store/listing-ko.md` | 준비됨 |
| 영어 문구 | `docs/store/listing-en.md` | 준비됨 |
| 스크린샷 | `docs/store/screenshots/*.png` (6장) | 준비됨 |
| 피처 그래픽 1024×500 | — | 미준비(사용자 제작) |
| 개인정보처리방침 | `docs/store/privacy-policy.html` + `.md` | 준비됨(사용자 호스팅) |
| 데이터 보안 | `docs/store/data-safety.md` | 준비됨 |
| 콘텐츠 등급 | `docs/store/content-rating.md` | 준비됨 |
| 가격(무료)/국가 | — | 사용자 설정 |

문의: geon@2ndsyndrome.com
