# HiteZero — Play Console 첫 제출 답안 시트 (복붙용)

> 작성 2026-06-14. 앱: **HiteZero** / 패키지 **com.gghf.hitezero** / 무료.
> 게임 성격: 칼 던지기 블록깨기 아케이드(조준→투척→벽 튕김, 네온 블록·RED_ENEMY, 하트 3).
> 전제(확인됨): **광고·인앱결제·온라인·계정·데이터 수집 전부 없음.** SDK 추가하면 이 시트도 갱신해야 함.
> 🔶 = 네가 최종 확인/선택할 항목.

---

## 0. 사전 준비
- 개발자 계정($25 1회 결제) 가입·신원확인 완료되어 있어야 함. 🔶
- 서명된 `hitezero.aab` 빌드 완료(가이드 `google_play_release.md` 4번). 🔶
- **앱 만들기**: Play Console → 앱 만들기 → 이름 `HiteZero`, 기본 언어 🔶(한국어 또는 영어), 앱/게임=**게임**, 무료/유료=**무료**.

---

## 1. 스토어 등록정보 (Main store listing)

- **앱 이름** (30자): `HiteZero`
- **간단한 설명** (80자):
  - EN: `Aim, ricochet knives, and smash neon blocks. One-handed arcade action.`
  - KR: `칼을 던지고 튕겨 네온 블록을 부숴라. 한 손으로 즐기는 네온 아케이드.`
- **자세한 설명** (4000자):

  EN:
  ```
  HiteZero is a fast, one-handed neon arcade game about throwing knives.

  Drag to aim, release to fire, and let your knives ricochet off the walls to
  smash every block on the board. Clear the STAR blocks to advance, trigger POW
  blocks for a radial knife burst, and watch out for RED ENEMY blocks that fall
  toward you — let one reach the bottom and you lose a heart.

  • Pure skill, no timers, no paywalls
  • Simple one-thumb controls — aim, release, smash
  • Ricochet physics: bank shots off walls and the tray
  • Escalating levels with more blocks and tougher enemies
  • Crisp neon visuals and punchy hit feedback
  • Plays fully offline — no ads, no account, no data collected

  How long can you survive with three hearts? Beat your best score and climb.
  ```

  KR:
  ```
  HiteZero는 칼을 던지는 빠른 한 손 네온 아케이드 게임입니다.

  드래그로 조준하고 놓아서 발사하세요. 벽에 튕기는 칼로 보드의 블록을 모두
  부숩니다. STAR 블록을 모두 깨면 다음 스테이지로, POW 블록은 방사형 칼 폭발을
  터뜨립니다. 아래로 떨어지는 RED ENEMY가 바닥에 닿으면 하트가 하나 줄어듭니다.

  • 순수 실력 — 타이머도, 결제 유도도 없음
  • 엄지 하나로 — 조준, 놓기, 파괴
  • 벽·트레이 튕김을 이용한 뱅크샷
  • 갈수록 늘어나는 블록과 강해지는 적
  • 선명한 네온 비주얼과 타격감
  • 완전 오프라인 — 광고·계정·데이터 수집 없음

  하트 3개로 얼마나 버틸 수 있나요? 최고 점수에 도전하세요.
  ```

- **그래픽 자산** (store_assets/ 에 준비됨):
  - 앱 아이콘 512×512 → `play_icon_512.png`
  - 그래픽 피처 1024×500 → `play_feature_1024x500.png`
  - 휴대전화 스크린샷(최소 2장) → `play_screen_1.png`, `play_screen_2.png` (1080×1890 ✓)
  - 🔶 스크린샷 2장 더 추가 권장(셀룩 캐릭터/스테이지 컷). 7인치/10인치 태블릿 스샷은 선택.
- **앱 카테고리**: 게임 → **아케이드**(또는 액션) 🔶
- **연락처 이메일**: `team.gghf@gmail.com`
- **개인정보처리방침 URL**: `https://hitezero.netlify.app/privacy`  ✅ 라이브

---

## 2. 앱 콘텐츠 (App content) — 좌측 메뉴 항목별 답안

### 2-1. 개인정보처리방침
- URL: `https://hitezero.netlify.app/privacy`

### 2-2. 광고
- 앱에 광고가 있나요? → **아니요 (No)**

### 2-3. 앱 액세스 권한
- 모든 기능이 제한 없이 제공되나요? → **예, 모든 기능이 특별한 액세스 없이 제공됨**
  (로그인·코드·멤버십 불필요)

### 2-4. 콘텐츠 등급 (IARC 설문) — 아래 그대로 답
- 이메일: `team.gghf@gmail.com`, 카테고리: **게임 / 기타(아케이드)**
- 폭력(Violence): 🔶 칼을 **추상적 블록과 만화풍 블롭(RED_ENEMY)**에 던짐. 사람·동물 캐릭터를 향한 사실적 폭력·유혈·상해 묘사 **없음** →
  - "사실적/노골적 폭력" → **아니요**
  - "유혈/피" → **아니요**
  - "판타지/만화적 폭력 요소" → 🔶 정직하게 **예**(칼 투척 액션). → 보통 *전체이용가~7세* 수준으로 산정됨.
- 성적 콘텐츠 → **아니요** (메이드 캐릭터는 일반 복장·비선정적 유지 🔶)
- 욕설/저속어 → **아니요**
- 약물/알코올/담배 → **아니요**
- 도박(실제/모의) → **아니요**
- 공포/무서움 → **아니요**
- 사용자 간 상호작용·위치 공유·UGC → **아니요**(온라인 기능 없음)
- → 결과: IARC가 자동 산정. 예상 **ESRB Everyone / PEGI 3~7 / 전체이용가**. 🔶 확정값은 설문 제출 후 표시.

### 2-5. 타깃층 및 콘텐츠 (Target audience and content)
- 대상 연령대 선택: 🔶 **권장 = 13세 이상**(만 13세 미만 포함 시 "가족 정책/Designed for Families" 추가 요건·심사가 붙음). 광고·데이터가 없어 가족용도 가능하나, 단순하게 가려면 13+.
- 어린이의 관심을 의도적으로 끄나요? → 🔶 (13+ 선택 시) **아니요**

### 2-6. 데이터 보안 (Data safety) — 핵심
- 앱이 사용자 데이터를 수집/공유하나요? → **아니요 (수집·공유 안 함)**
- 수집하는 데이터 유형: **없음**
- 공유하는 데이터 유형: **없음**
- 전송 중 암호화: 해당 없음(데이터 미수집). 양식이 강제하면 "데이터를 수집하지 않음" 경로 선택.
- 사용자가 데이터 삭제를 요청할 수 있나요: 해당 없음(서버 미보관, 기기 로컬만).
- → 결과 라벨: **"데이터가 수집되지 않음"**.

### 2-7. 기타 선언
- 정부 앱 → 아니요 / 금융 기능 → 아니요 / 건강 → 아니요
- 뉴스 앱 → 아니요 / 코로나19 추적·접촉 → 아니요
- 데이터 보안 — 위 2-6
- 미국 수출법 준수 → 동의 🔶

---

## 3. 출시 (Release) — 트랙

1. 먼저 **내부 테스트(Internal testing)** 트랙 생성 → `hitezero.aab` 업로드 → 테스터(본인 이메일) 추가 → 링크로 실기기 설치·1회 풀플레이 검증. 🔶
2. **Play 앱 서명**: 첫 업로드 시 자동 안내 → **켜기**(업로드 키 = `new_upload_key.jks`).
3. 이상 없으면 **비공개 테스트 → 프로덕션** 순으로 승격. 첫 제출은 구글 심사 며칠 소요될 수 있음.
- 버전: `versionCode=1`, `versionName=1.0.0` (이후 업데이트마다 code +1).

---

## 4. 제출 전 최종 체크
- [ ] 서명된 .aab (APK 아님) 업로드됨
- [ ] 개인정보처리방침 URL 등록됨 (https://hitezero.netlify.app/privacy)
- [ ] 데이터 안전 = "데이터 수집 안 함"
- [ ] 콘텐츠 등급 설문 제출 완료
- [ ] 타깃 연령대 선택 🔶
- [ ] 광고 = 없음
- [ ] 스토어 등록정보(설명·아이콘·피처·스샷2+) 완료
- [ ] 내부 테스트로 실기기 1회 풀플레이 OK

> 막히는 칸 있으면 캡처해서 보내. 답안 같이 맞춰줄게. AAB 빌드 에러(프리셋 경고·gradle)도 같이 본다.
