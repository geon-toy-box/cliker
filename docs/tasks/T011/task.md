---
task: T011
project: cliker
milestone: M3
created: 2026-06-22
status: TODO
tags: [toybox, task]
---

# T011 — Store listing metadata + privacy policy

## Context
서명된 AAB(T010)가 있어도 Play Console 등록에는 스토어 문구·스크린샷·개인정보처리방침·
데이터 안전/콘텐츠 등급 정보가 필요하다. 이 작업은 그 자료 일체를 `docs/store/`에 준비해,
사용자가 복사-붙여넣기로 바로 등록할 수 있게 한다. (실제 업로드는 사용자 몫.)

## Scope — what to build (docs only, under `docs/store/`)
- `listing-ko.md`, `listing-en.md` — 앱 제목(≤30자, KO="클리커"), 짧은 설명(≤80자),
  자세한 설명(≤4000자), 카테고리 제안, 태그/키워드, 연락 이메일(geon@2ndsyndrome.com).
- `privacy-policy.md` + `privacy-policy.html` — 개인정보처리방침: 이 앱은 **개인정보를 수집/전송하지
  않으며**, 클릭 수·설정 등은 **기기 로컬에만** 저장, 네트워크/광고/분석 없음. Play는 공개 URL을
  요구하므로, 사용자가 호스팅(예: GitHub Pages)할 수 있도록 완성된 HTML 제공 + 호스팅 방법 안내.
- `data-safety.md` — Play "데이터 보안" 양식 작성용 답변(수집/공유 데이터 없음, 로컬 저장만).
- `content-rating.md` — IARC 콘텐츠 등급 설문 답변 가이드(유해 콘텐츠 없음 → 전체이용가 예상).
- `screenshots/` — 에뮬레이터에서 실제 앱 폰 스크린샷 최소 2~8장(홈/타건/설정/통계/스위치 선택 등),
  Play 권장 해상도. 캡처 방법/원본 포함.
- `store-checklist.md` — 업로드 체크리스트(AAB, 아이콘, 스크린샷, 제목/설명, 개인정보 URL,
  데이터 보안, 콘텐츠 등급, 가격=무료, 배포 국가). 각 항목이 어디서 오는지(어느 산출물) 링크.

## Out of scope
- 실제 Play Console 등록/업로드(사용자 수행). 개인정보처리방침의 실제 호스팅(URL 발급)은 사용자.
- 앱 코드 변경(이 작업은 문서/자료만).

## Acceptance criteria (QA verifies each)
- [ ] AC1: `docs/store/`에 listing-ko.md, listing-en.md, privacy-policy.md, privacy-policy.html, data-safety.md, content-rating.md, store-checklist.md가 모두 존재.
- [ ] AC2: 제목/짧은 설명/자세한 설명이 Play 길이 제한(30/80/4000자)을 **초과하지 않음** — QA가 글자수 측정해 확인.
- [ ] AC3: 개인정보처리방침이 앱 실제 동작과 일치(로컬 저장만, 네트워크/수집 없음) — 앱이 INTERNET 권한/네트워크 코드가 없음을 교차 확인(코드/매니페스트 대조).
- [ ] AC4: `screenshots/`에 유효한 PNG 폰 스크린샷이 최소 2장 있고 실제 앱 화면임(홈 키캡 등 식별 가능).
- [ ] AC5: store-checklist.md가 업로드에 필요한 모든 항목을 나열하고 각 항목의 산출물 위치를 가리킴.
- [ ] AC6: 앱 코드/테스트 무변경 확인(`flutter analyze` clean·`flutter test` green 유지 — 회귀 없음).

## Test plan — which pyramid layers apply
- Format / Analyze: required (코드 무회귀 확인)
- Unit/Widget/Golden/Integration: N/A: 문서/자료 산출물 (앱 코드 변경 없음)
- Build: N/A: 코드 변경 없음(AAB는 T010 산출물 사용)
- Runtime smoke: 스크린샷 캡처를 위해 에뮬레이터에서 앱 실행(자료 생성 목적)

## Evidence
- Dev evidence:  docs/tasks/T011/evidence/dev/
- QA evidence:   docs/tasks/T011/evidence/qa/
