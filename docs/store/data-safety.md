# 데이터 보안 (Data safety) 양식 답변 — 클리커 (cliker)

> Google Play Console → 앱 콘텐츠 → **데이터 보안(Data safety)** 양식 작성용 가이드.
> 아래 답변을 그대로 선택/입력하면 된다. 근거: 앱은 인터넷 권한이 없고 외부로 어떤
> 데이터도 전송하지 않으며, 클릭 통계·설정만 기기 로컬(SharedPreferences)에 저장한다.
> (코드/매니페스트 교차검증은 privacy-policy.md 및 dev.md AC3 참조.)

---

## 1. 데이터 수집 및 공유 (Data collection and sharing)

| 질문 | 답변 |
|------|------|
| 이 앱이 사용자 데이터를 수집하거나 공유하나요? (Does your app collect or share any of the required user data types?) | **아니요 (No)** |

> "아니요"를 선택하면 아래의 데이터 유형별 세부 질문은 나타나지 않는다. 앱은 어떤
> 사용자 데이터도 **수집(collect)** 하거나 **공유(share)** 하지 않기 때문이다.
> ("수집"은 앱이 기기 밖으로 데이터를 전송하는 것을 의미한다. 본 앱은 전송이 없다.)

---

## 2. 기기 로컬 저장에 대한 참고 (왜 "수집 안 함"인지)

- 앱은 클릭 통계(누적 클릭 수, 최고 CPM)와 설정(스위치/LED 색/LED 모드/사운드·햅틱
  토글)을 **기기 내부 SharedPreferences에만** 저장한다.
- Play의 데이터 보안 기준에서 **기기에서만 처리되고 외부로 전송되지 않는 데이터는
  "수집"으로 보지 않는다.** 따라서 1번 답은 "아니요(No)"가 맞다.
- 저장 데이터는 개인을 식별하지 않으며, 앱 삭제 시 함께 제거된다.

---

## 3. 보안 관행 (Security practices) — 해당 시 표기

| 항목 | 답변 |
|------|------|
| 전송 중 데이터 암호화 (Data encrypted in transit) | **해당 없음** — 네트워크 전송 자체가 없음 |
| 사용자가 데이터 삭제를 요청할 수 있나요? (Users can request data deletion) | 앱 내 "초기화" 버튼으로 통계 삭제 가능 + 앱 삭제 시 전체 제거. 외부 보관 데이터가 없어 별도 삭제 요청 채널 불필요 |

---

## 4. 핵심 한 줄 요약 (양식 제출용)

- 수집 데이터: **없음 (None)**
- 공유 데이터: **없음 (None)**
- 데이터 필수 여부: **앱 사용에 어떤 데이터도 필수가 아님 (No data required)**
- 저장 위치: **기기 로컬 전용 (on-device only, SharedPreferences)**

문의: leegeondev@gmail.com
