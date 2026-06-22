---
project: cliker
package: cliker
org: com.secondsyndrome
created: 2026-06-22
status: planning
tags: [toybox, project, planner]
---

# cliker — Planner

> Master plan owned by the **Planner**. This is the single source of truth for
> what the product is and what work remains. Workers never edit this file; they
> write `docs/tasks/<id>/{dev,qa}.md`, and the Planner reflects verified results
> back here. Every status here must trace to evidence in a task's `evidence/`.

## Product vision
**cliker — LED 클릭커 키캡 (스트레스 해소 앱).** 화면 중앙의 큼직한 기계식 키캡
하나를 누르면 진짜 키보드처럼 **타건음(사운드) + 진동(햅틱) + LED 빛 효과**가
터지고, 누른 만큼 **클릭 카운터/통계**가 쌓인다. 멍하니 또는 집중해서 키캡을
연타하며 스트레스를 푸는 가벼운 피젯(fidget) 토이. 청축·갈축·적축 등 여러 기계식
스위치 음색을 골라 자기 취향의 타건감을 만든다. Android 전용, 오프라인 동작,
권한 최소(진동만).

대상: 키보드 타건감/ASMR·피젯 토이를 좋아하는 사람, 잠깐의 스트레스 해소가 필요한
사람. "좋다"의 기준 = 탭 → 피드백 지연이 체감되지 않고(저지연), 연타가 끊기지 않으며,
한 번 더 누르고 싶은 만족감.

## Definition of "shippable"
- [ ] 핵심 루프가 실기기에서 끝까지 동작: 키캡 탭 → 저지연 타건음 + 진동 + LED + 카운터 증가 (smoke evidence)
- [ ] 콜드 스타트/네트워크 없음/권한 거부/회전에서 크래시 없음
- [ ] 스위치 선택·LED·통계가 앱 재시작 후에도 유지(영구 저장)
- [ ] 정적 분석 clean(`No issues found!`), 테스트 피라미드 green, `dart format` clean
- [ ] Google Play Console 업로드 가능: 실 app id, 릴리스 서명, 앱 아이콘/이름, AAB 빌드 성공, 스토어 등록 메타데이터 준비

## Milestones
| # | Milestone | Goal | Status |
|---|-----------|------|--------|
| M1 | Core clicker MVP | 단일 대형 키캡 탭 → 타건음+진동+LED+카운터가 저지연으로 동작하고 스위치 선택/통계가 영구 저장되는 동작하는 앱 | TODO |
| M2 | Polish & customization | LED 효과 모드(리플·RGB 사이클·반응형), 색상 커스터마이즈, 설정 화면, 통계 패널(누적·세션·CPM·최고기록) | TODO |
| M3 | Play Store readiness | 앱 아이콘/이름, app id 확정, 릴리스 서명(keystore), 버전, AAB 빌드, 권한 점검, 스토어 등록 메타데이터·개인정보처리방침 | TODO |

## Task backlog
> Statuses: TODO · IN_PROGRESS · BLOCKED · NEEDS_FIX · VERIFIED · DONE
> A task may only become VERIFIED via QA, and DONE only with a commit hash.

| id | title | milestone | depends on | status | verified-by |
|----|-------|-----------|------------|--------|-------------|
| T001 | Foundation: dependencies + dark RGB theme tokens | M1 | — | TODO | — |
| T002 | Switch domain catalog + synthesized switch sound assets | M1 | T001 | TODO | — |
| T003 | Persistence + settings & stats state (Riverpod) | M1 | T002 | TODO | — |
| T004 | Audio service (low-latency soundpool) + haptics service | M1 | T002 | TODO | — |
| T005 | Keycap widget + LED ripple/glow effects | M1 | T001 | TODO | — |
| T006 | Home screen wiring (keycap + audio + haptics + stats + switch selector) | M1 | T003,T004,T005 | TODO | — |
| T007 | Settings & customization (LED modes, color, sound/haptic toggles) | M2 | T006 | TODO | — |
| T008 | Stats panel (total · session · CPM · best) + reset | M2 | T006 | TODO | — |
| T009 | App identity: launcher icon + app name + versioning | M3 | T006 | TODO | — |
| T010 | Release build: signing config + AAB + permissions audit | M3 | T009 | TODO | — |
| T011 | Store listing metadata + privacy policy | M3 | T010 | TODO | — |

## Decisions log
<!-- Architecture/product decisions, dated, with the reasoning. Prevents re-litigating. -->
- 2026-06-22: Stack = Flutter (Android-only) + Riverpod. Testability + compile-time safety.
- 2026-06-22: 레이아웃 = **단일 대형 키캡**(사용자 선택). MVP로 깔끔하고 몰입감 높음.
- 2026-06-22: 피드백 4종 모두 포함(사용자 선택): 타건음 + 햅틱 + LED + 카운터/통계.
- 2026-06-22: 스위치 = **여러 종 선택**(사용자 선택). v1 카탈로그: 청축(blue)·갈축(brown)·적축(red)·흑축(black).
- 2026-06-22: 사운드 = 라이선스 리스크 회피 위해 **합성(synthesized) WAV**를 커밋된 파이썬 스크립트로 생성·번들. 외부 다운로드/저작권 자산 미사용.
- 2026-06-22: 저지연 연타 위해 오디오는 **soundpool**(Android SoundPool 래퍼) 사용. 탭다운=down음, 탭업=up음. pub 해상도/빌드 실패 시 audioplayers low-latency를 문서화된 폴백으로 둔다.
- 2026-06-22: 설정/통계 영구 저장 = **shared_preferences**(단순 key-value). devlingo는 hive를 썼으나 여기선 카운터·토글 위주라 더 가벼운 선택.
- 2026-06-22: app id = `com.secondsyndrome.cliker` (이메일 도메인 2ndsyndrome.com 기반; 'com.2ndsyndrome'은 세그먼트가 숫자로 시작해 Android 규칙 위반이라 secondsyndrome로 변환). 퍼블리시 전 사용자 확정 필요.
- 2026-06-22: 디자인 = 다크 + 네온 RGB 게이밍 무드(키보드 LED 감성). 라이트 테마 없음(v1).

## Open questions (for the user)
<!-- Things the Planner needs the user to decide. Resolve via tiki-taka, then move to Decisions. -->
- app id `com.secondsyndrome.cliker` 그대로 갈지, 다른 reverse-DNS를 쓸지 (퍼블리시 전 확정).
- 릴리스 keystore: 내가 업로드 키스토어를 생성해 드릴지(사용자가 안전 백업), 아니면 사용자가 직접 만들지 (M3 진입 시 결정).
- 앱 표시 이름: "cliker" / "클리커" / 다른 이름?

## Reflected results
<!-- Append-only. Each entry is the Planner's audited summary of a completed task,
     citing the qa.md verdict and commit it trusts. -->
