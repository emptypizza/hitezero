# HiteZero — Play Console 첫 제출 답안 시트 (복붙용)

> 작성 2026-06-14. 앱: **HiteZero** / 패키지 **com.gghf.hitezero** / 무료.
> 게임 성격: 칼 던지기 블록깨기 아케이드(조준→투척→벽 튕김, 네온 블록·RED_ENEMY, 하트 3).
> 전제(확인됨): **광고·인앱결제·온라인·계정·데이터 수집 전부 없음.** SDK 추가하면 이 시트도 갱신해야 함.
> 🔶 = 네가 최종 확인/선택할 항목 · ✅ = 정밀 검증으로 확정됨(2026-06-14, 멀티에이전트 정책 감사 + 캐릭터 아트 시각 검수).

---

## 0. 사전 준비
- 개발자 계정($25 1회 결제) 가입·신원확인 완료되어 있어야 함. 🔶
- 서명된 `hitezero.aab` 빌드 → **GitHub Actions CI가 자동 생성** (`.github/workflows/android.yml`). `v*` 태그 푸시(예: `git tag v1.0.0 && git push origin v1.0.0`) 또는 Actions 탭 → "Android (AAB + APK)" → Run workflow 실행 → 실행 결과의 Artifacts(`hitezero-android`)에서 `hitezero.aab` 다운로드. 서명은 리포 시크릿(`ANDROID_KEYSTORE_BASE64`/`ANDROID_KEY_ALIAS`/`ANDROID_KEYSTORE_PASSWORD`)으로 처리됨. ✅
- **앱 만들기**: Play Console → 앱 만들기 → 이름 `HiteZero`, **기본 언어 = 영어(en-US)** (확정 ✅), 앱/게임=**게임**, 무료/유료=**무료**.
  - 출시 후 스토어 등록정보에 **한국어(ko-KR)를 추가 언어로 등록** → 아래 1번의 KR 텍스트를 사용. (영어 기본 = 글로벌 노출 최대화, 한국어 추가 = 국내 시장 커버)

---

## 1. 스토어 등록정보 (Main store listing)

- **앱 이름** (최대 30자): `HiteZero` (en-US / ko-KR 공통, 8자 ✓)
- **간단한 설명** (80자):
  - EN (en-US, 70/80자 ✓): `Aim, ricochet knives, and smash neon blocks. One-handed arcade action.`
  - KR (ko-KR, 40/80자 ✓): `칼을 던지고 튕겨 네온 블록을 부숴라. 한 손으로 즐기는 네온 아케이드.`
- **자세한 설명** (최대 4000자 / EN 746자 ✓ · KR 352자 ✓ — 두 언어 모두 한도 내·내용 완비):

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
  - 휴대전화 스크린샷(최소 2장 충족 ✓) → `play_screen_1.png`, `play_screen_2.png` (각 1080×1890, 9:16 세로, Play 허용 비율·최소 해상도 충족 ✓)
  - 🔶 스크린샷 2장 더 추가 권장(셀룩 캐릭터/스테이지 컷). 7인치/10인치 태블릿 스샷은 선택.
- **앱 카테고리**: 게임 → **아케이드 (Arcade)** ✅ 확정
  - 근거: 단일 화면 칼 던지기·벽 튕김 블록깨기(조준→투척→스테이지 클리어, 하트 3, 점수 도전형) = 전형적 아케이드 패턴. '액션'은 실시간 전투/반사신경 슈팅·플랫포머용 카테고리이며 본 게임은 캐릭터 대 캐릭터 전투가 없음(메이드는 비전투 투척 아바타 = 사실상 패들, 표적은 추상 네온 블록과 만화풍 블롭). IARC 자가등급(경미한 판타지/만화 폭력, 전체이용가)과도 일치.
- **연락처 이메일**: `team.gghf@gmail.com`
- **개인정보처리방침 URL**: `https://hitezero.netlify.app/privacy`  ✅ 라이브

---

## 2. 앱 콘텐츠 (App content) — 좌측 메뉴 항목별 답안

### 2-1. 개인정보처리방침
- URL: `https://hitezero.netlify.app/privacy`

### 2-2. 광고
- 앱에 광고가 있나요? → **아니요 (No)** ✅ 확정
  - 근거: 광고·분석·추적 SDK 미포함(privacy.html §3), INTERNET 권한 없음·완전 오프라인이라 광고 서빙 자체가 불가.
- 인앱결제(IAP)가 있나요? → **아니요 (No)** — 앱은 **무료**, IAP 없음. (가격 설정에서 무료/IAP 없음 유지)

### 2-3. 앱 액세스 권한
- 모든 기능이 제한 없이 제공되나요? → **예, 모든 기능이 특별한 액세스 없이 제공됨** ✅ 확정
  (로그인·코드·멤버십·지역 제한 불필요. 설치 즉시 Boot→Title→Game 전 기능 접근 가능, 심사팀에 제공할 접근 자격증명 없음)

### 2-4. 콘텐츠 등급 (IARC 설문) — 아래 그대로 답
- 이메일: `team.gghf@gmail.com`, 카테고리: **게임 / 기타(아케이드)**
- 폭력(Violence): 칼을 **추상적 네온 블록과 만화풍 블롭(RED_ENEMY)**에만 던짐. 사람·동물 캐릭터를 향한 사실적 폭력·유혈·상해 묘사 **없음**. (RED_ENEMY는 바닥 도달 시 하트만 차감 후 제거 — 사망 연출 없음.) →
  - "사실적/노골적 폭력" → **아니요**
  - "유혈/피" → **아니요**
  - "판타지/만화적 폭력 요소" → 정직하게 **예**(칼 투척 액션, 추상 블록·만화 블롭 대상, 유혈·사실적 폭력 없음). 절대 '아니요'로 낮추지 말 것 — 과소신고는 등급 취소·앱 제거 사유. → 보통 *전체이용가~PEGI 7* 수준으로 산정됨. (콘텐츠가 아동 적합=낮은 등급으로 나오는 사실은 2-5의 '아동 어필 가능'과 모순 아님 — 정직하게 일관 유지.)
- 성적 콘텐츠 → **아니요** (검수 완료 ✅: 메이드 캐릭터는 치비 비율의 전신 의상 — 풀커버 드레스·앞치마·무릎길이 치마·허벅지까지 오는 스타킹·헤드드레스. 노출/클리비지/업스커트 프레이밍 없음, 전투 포즈만. 노출/암시 복장으로 변경 금지하여 이 답 유지.)
- 욕설/저속어 → **아니요**
- 약물/알코올/담배 → **아니요**
- 도박(실제/모의) → **아니요**
- 공포/무서움 → **아니요**
- 사용자 간 상호작용·위치 공유·UGC → **아니요**(온라인 기능 없음)
- → 결과: IARC가 자동 산정. 예상 **ESRB Everyone / PEGI 3~7 / USK 0~6 / 전체이용가**. 🔶 확정값은 설문 제출 후 표시.
  - 참고: 이 IARC 자동 등급(3+)과 2-5의 'Play 타깃 연령 13+'는 서로 다른 제도(콘텐츠 등급 vs. 타깃층 자가선택)이며 값이 달라도 정상 — 둘 다 그대로 두면 됨.

### 2-5. 타깃층 및 콘텐츠 (Target audience and content)
- 대상 연령대 선택: ✅ **확정 = 13세 이상(13+)만 선택** — 만 13세 미만 연령 그룹은 선택하지 않음. (만 13세 미만을 한 개라도 포함하면 Google Play **가족 정책 / Designed for Families** 프로그램이 발동되어 가족용 광고 SDK 인증·COPPA/GDPR-K 아동 데이터 선언·아동 적합 콘텐츠 보장 등 추가 요건과 심사가 붙는다. 본 앱은 광고·데이터 수집이 전무해 기술적으로는 가족용도 가능하나, 최초 출시는 13+만 선택해 가족 정책 **비대상**으로 두는 것이 가장 단순하고 방어 가능하다.)
- 앱이 어린이의 관심을 끌도록 **의도적으로(주 대상으로) 설계**되었나요? → **아니요** (주 대상은 13세 이상).
  - 정직성 메모(중요): 본 앱 아트(치비 애니메 메이드 캐릭터, 밝은 네온 블록·별·POW·만화 블롭)는 어린 사용자에게도 **부수적으로 어필할 수 있음**을 인정. Google이 콘텐츠 기반으로 아동 어필을 판단하더라도 (1) 대상 연령대를 13+만 선택했고 (2) 광고 0·데이터 수집 0이므로 가족 정책상 실질 위험은 낮다. → '아동을 **주 대상**으로 하는가'에는 정직하게 **아니요**로 답하되, '아동에게도 **어필 가능**한가' 항목이 별도로 뜨면 **사실대로** 표기하고 단순 부정하지 말 것(잘못된 표현 = 정책 위반 위험).

### 2-6. 데이터 보안 (Data safety) — 핵심
- 앱이 사용자 데이터를 수집/공유하나요? → **아니요 (수집·공유 안 함)**
  - (확인됨) 진행 상황·설정은 기기 내 `user://save.cfg`에만 저장되고 어떤 서버로도 전송되지 않으므로 Play 데이터 보안 기준상 '수집'에 해당하지 않음. 개인정보처리방침(privacy.html §1·§5)과 일치.
- 수집하는 데이터 유형: **없음**
- 공유하는 데이터 유형: **없음**
- 전송 중 암호화: 해당 없음(데이터 미수집). 양식이 강제하면 "데이터를 수집하지 않음" 경로 선택.
- 사용자가 데이터 삭제를 요청할 수 있나요: 해당 없음(서버 미보관, 기기 로컬만).
- → 결과 라벨: **"데이터가 수집되지 않음 · 데이터가 공유되지 않음" (No data collected / No data shared)**.
  - 검증 근거: 네트워크 코드·INTERNET 권한·광고/분석 SDK 전무(`permissions/custom_permissions`=빈 배열, `permissions/vibrate=true`만 존재). 유일한 저장은 기기 로컬 `user://save.cfg`(최고점수·스테이지·코인·업그레이드·통계·음소거 설정)로 외부 전송 없음 → Play 정의상 '수집' 아님.

### 2-7. 기타 선언 ✅ 전부 확정
- 정부 앱 → **아니요** / 금융 기능 → **아니요** / 건강 → **아니요**
- 뉴스 앱 → **아니요** / 코로나19 추적·접촉(contact tracing/status) → **아니요**
- 인앱결제 → **아니요** (앱 무료, IAP 없음)
- 데이터 보안 — 위 2-6 ("데이터 수집 안 함")
- 미국 수출법 준수 → **동의(체크)** ✅ — 앱 내 자체 암호화 없음, 완전 오프라인(INTERNET 권한 없음)·표준 OS 암호화만 사용 → 표준 배포 대상, 준수 확인란 체크.

---

## 3. 출시 (Release) — 트랙

1. 먼저 **내부 테스트(Internal testing)** 트랙 생성 → CI 아티팩트로 받은 `hitezero.aab` 업로드(GitHub Actions `Android (AAB + APK)` 워크플로가 `v*` 태그/수동 실행 시 서명된 AAB를 생성) → 테스터(본인 이메일) 추가 → 링크로 실기기 설치·1회 풀플레이 검증. 🔶
2. **Play 앱 서명(Play App Signing)**: 첫 업로드 시 자동 안내 → **켜기**(첫 업로드 시 활성화). 구글이 앱 서명 키를 관리하고, 우리는 **업로드 키 = `hitezero_upload.jks`**(별칭 `upload`)로만 업로드함.
   - 업로드 인증서 SHA-256: `8F:21:9B:30:0C:B8:1F:74:06:31:A7:F2:60:7C:2D:6E:81:84:7E:86:6A:71:27:C5:88:24:38:44:C8:42:A1:62` — 첫 업로드 후 Play Console에 등록된 업로드 인증서와 일치하는지 확인.
   - 이 키는 GitHub Actions 리포 시크릿(`ANDROID_KEYSTORE_BASE64` = base64(hitezero_upload.jks), `ANDROID_KEY_ALIAS`=`upload`, `ANDROID_KEYSTORE_PASSWORD`)으로 등록되어 CI가 서명된 AAB를 자동 빌드함. `hitezero_upload.jks`와 비밀번호(`~/keystores/hitezero_upload.password.txt`)는 오프라인에 백업해 둘 것(분실 시 향후 업데이트 업로드 불가).
3. 이상 없으면 **비공개 테스트 → 프로덕션** 순으로 승격. 첫 제출은 구글 심사 며칠 소요될 수 있음.
- 버전: `versionCode=1`, `versionName=1.0.0` (확인됨). 이후 업로드마다 `versionCode`를 **+1** 해야 함(동일 코드 재사용 시 Play가 업로드 거부).

---

## 4. 제출 전 최종 체크
- [ ] 서명된 .aab (APK 아님) 업로드됨
- [ ] 개인정보처리방침 URL 등록됨 (https://hitezero.netlify.app/privacy)
- [ ] 데이터 안전 = "데이터 수집 안 함 / 공유 안 함"
- [ ] 콘텐츠 등급 설문 제출 완료 (판타지/만화 폭력=예, 나머지=아니요)
- [ ] 타깃 연령대 = **13+** 선택 (만 13세 미만 미포함)
- [ ] 광고 = 없음 / 인앱결제 = 없음
- [ ] 미국 수출법 준수 체크
- [ ] 스토어 등록정보(설명·아이콘·피처·스샷2+) 완료
- [ ] 내부 테스트로 실기기 1회 풀플레이 OK
- [ ] (출시 전) `ANDROID_KEYSTORE_BASE64` 시크릿이 cert SHA-256 `8F:21:…:A1:62` 키스토어로 디코드되는지 확인(`keytool -list -v`) — 첫 업로드가 업로드 키를 영구 고정함. (※ 이 시크릿은 해당 키스토어로부터 직접 등록되어 이미 일치 — 재확인만)

> 막히는 칸 있으면 캡처해서 보내. 답안 같이 맞춰줄게. AAB 빌드 에러(프리셋 경고·gradle)도 같이 본다.
