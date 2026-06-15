# 인수인계 — Cursor 터미널 Claude에게 (2026-06-14, 지금 당장 할 것)

> 넘기는 이: Cowork 에이전트. **내 샌드박스는 마운트 동기화가 불안정해 `dist/`·`build/`의
> 웹빌드(`godot.wasm`)가 안 닿고, Godot/Android SDK도 없다.** 너(터미널 Claude)는 실제 로컬
> 파일 + Godot가 다 있으니 아래를 네가 실행해라. 라이브 사이트·실파일은 멀쩡하다.
> 레포: `emptypizza/hitezero` · 브랜치 `neon-style-7cc31` · Godot **4.6.2** · 패키지 `com.gghf.hitezero`.

---

## ★ 1순위 — Netlify "폴리싱본" 재배포 (내가 준비만 하고 못 올린 것)

**현재 상태(확인됨):** `hitezero.netlify.app` 라이브는 6/13 빌드(배포 ID `6a2e2976…`).
**폴리싱(파비콘·OG·메타)은 아직 안 올라감** — 라이브 index.html에 og/favicon 메타 없음.

**이미 준비된 것(레포에 있음):**
- 폴리싱 자산: `store_assets/web/` → `favicon-16/32/48/180/192/512.png`, `og_image_1200x630.png`
- `<head>` 주입 스니펫 문서: `godot/docs/web_polish.md`
- 원클릭 빌더: `godot/tools/deploy_netlify_polished.sh` (빌드폴더→폴리싱 publish폴더 생성, 빈 인자 가드 있음)

**실행 (그대로 복붙):**
```bash
# (1) 폴리싱 publish 폴더 생성 — 존재하는 웹빌드 폴더로. 셋 중 있는 것 사용:
#     dist/godot-web/site_nothreads  |  build/godot-web/site_nothreads  |  dist/hitezero-itch-html
ls dist/godot-web/site_nothreads build/godot-web/site_nothreads dist/hitezero-itch-html 2>/dev/null
bash godot/tools/deploy_netlify_polished.sh dist/godot-web/site_nothreads dist/netlify-polished

# (2) 기존 사이트(hitezero.netlify.app)로 배포 — netlify CLI (새 Drop 사이트 만들지 말 것!)
npm i -g netlify-cli 2>/dev/null || true
netlify login                      # 네 계정 브라우저 인증 (또는 NETLIFY_AUTH_TOKEN 환경변수)
netlify deploy --prod --dir=dist/netlify-polished \
  --site=742653ed-62bd-4e8b-bcd0-a85cc36ac4ed
```
> ⚠️ **app.netlify.com/drop은 새 랜덤 사이트가 생겨 hitezero.netlify.app을 안 바꾼다.** 기존
> 사이트를 갱신하려면 위 `netlify deploy --site=<id>`를 써라.
> ⚠️ 최신 게임을 반영하려면, 위 빌드폴더가 최신인지 확인(아니면 먼저 `bash godot/tools/build_web.sh dist/godot-web`로 재export 후 그 폴더 사용).

**검증(반드시):**
```bash
curl -s https://hitezero.netlify.app/ | grep -E 'og:image|favicon|description'   # 메타 떠야 함
curl -sI https://hitezero.netlify.app/og_image_1200x630.png | head -1            # 200
curl -sI https://hitezero.netlify.app/privacy | head -1                          # 200 유지
```
브라우저 탭 파비콘 + 링크 공유 미리보기(OG) 눈으로 확인.

---

## 2순위 — 변경분 커밋 (사람 확인 후, 시크릿 금지)

이번 세션 신규/변경(커밋 대상). `git status`로 대조 후 변경요약 보고하고 커밋:
```
 .github/workflows/android.yml            (CI: 서명 AAB+APK)        ← 이미 다듬어짐
 godot/docs/android_ci.md                 (CI 사용법)
 godot/docs/play_console_submission.md    (Play 제출 답안)          ← 검증 보강됨
 godot/docs/web_polish.md                 (웹 폴리싱 스니펫)
 godot/docs/higgsfield_worklist.md        (아트 10작업 큐)
 godot/docs/HANDOFF_*.md                  (인수인계)
 godot/export_presets.cfg                 (launcher_icons 4줄 연결)
 godot/android_icons/                     (아이콘 4 PNG)
 godot/tools/ai_sprite_cleanup.py         (AI→도트 정리)
 godot/tools/deploy_netlify_polished.sh   (폴리싱 배포 빌더)
 store_assets/privacy.html                (개인정보처리방침)
 store_assets/web/                        (파비콘 6 + OG)
 higgsfield_proofs/                       (H1 드롭인 증명 — 대용량, 커밋 선택)
 .gitignore                               (*.jks 등 제외 추가)
```
- **커밋 금지:** `*.jks`/`*.b64`/키 비번, 루트의 `hitezero-*.zip`(빌드 산출물), `build/`·`dist/netlify-polished/`(이미 .gitignore).
- `export_presets.cfg`의 keystore 칸이 비어있는지 커밋 전 확인.

---

## 3순위 — Android AAB/APK (CI, 출시용)

워크플로 `.github/workflows/android.yml` 준비됨(Godot 4.6.2, barichello 이미지, 빌드템플릿 수동추출·SDK/JDK 경로 주입 픽스 반영).
1. **리포 시크릿 등록**(없으면): Settings→Secrets→Actions →
   `ANDROID_KEYSTORE_BASE64`(=base64 `hitezero_upload.jks`), `ANDROID_KEY_ALIAS`=`upload`, `ANDROID_KEYSTORE_PASSWORD`.
2. **트리거:** `git tag v1.0.0 && git push origin v1.0.0` (또는 Actions→Run workflow).
3. **다운로드:** 실행 Artifacts `hitezero-android` → `hitezero.aab`(Play용) + `hitezero.apk`(테스트).
4. **검증:** AAB가 **업로드키 서명**인지(디버그 아님). 업로드 인증서 SHA-256 = `8F:21:9B:30:0C:B8:1F:74:06:31:A7:F2:60:7C:2D:6E:81:84:7E:86:6A:71:27:C5:88:24:38:44:C8:42:A1:62`.
5. **제출:** `godot/docs/play_console_submission.md` 답안대로 Play 내부테스트 업로드 → 실기 1회 풀플레이 → 프로덕션.

---

## PARKED — 부르기 전엔 손대지 말 것
- **Higgsfield 아트 H4~H9**(Soul·프레임셋·적/보스·스토어·영상·배경): **크레딧 0**, 업그레이드(PLUS $49=1000cr) 후 `godot/docs/higgsfield_worklist.md`의 턴키 사양대로. **출시(Play) 그린이 먼저.**
- **H1 드롭인 통합**: 룩 승인 시 `ai_sprite_cleanup.py`로 정리→`assets/textures/player/maid/` 교체→`player.gd` 프레임배열만 갱신→`tools/test_player_output_vfx.py` 통과해야 repo 투입. gameplay_spec 계약 불변.
- **Nemo_DO / Lightning Rider / asset-cloud** = 다른 프로젝트, 범위 밖.

## 하드 룰
- 검증 없이 완료 선언 금지(배포·빌드 후 실제 확인). 시크릿 커밋 금지. git 커밋은 사람 확인 후.
- Play엔 AAB만(APK는 테스트). versionCode는 업데이트마다 +1.
- 게임플레이 계약(`godot/docs/gameplay_spec.md` 상수·상태머신) 불변.

## 한 줄 요약
**지금 당장: ①`deploy_netlify_polished.sh`로 폴리싱 publish 만들고 `netlify deploy --site=742653ed…`로 hitezero.netlify.app 갱신 → ②검증 → ③변경분 커밋 → ④`v1.0.0` 태그로 AAB 빌드 → Play 제출.**
