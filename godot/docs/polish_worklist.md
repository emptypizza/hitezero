# HiteZero — 폴리싱 작업 로그 (2026-06-15)

> game-maker 세션. 웹 4팀 리서치(Godot 4.6 공식문서·GDC·ASO 2025-26, 전부 출처 포함) +
> 코드 직독 기반으로 P1~P10을 상용(유료앱) 기준으로 작업. **각 항목 = 구현+검증 / ready-spec** 표기.
> 하드룰 준수: gameplay_spec 로직 상수·player.gd 피벗 불변, 테스트 그린, 라이브 안 깸.
> 베이스라인→변경후 모두 **python 7/7 PASS + 헤드리스 부팅 클린** 확인.

## ✅ 구현 + 검증 완료 (코드 반영, 회귀 0)

### P3 — 플랫폼 인지 컨트롤 힌트 (실버그 수정)
- **버그였음**: `title.gd` footer가 "Keyboard: A/D"를 **모바일에도** 노출. `OS.has_feature("mobile")`은 **웹 빌드에서 false**(웹은 "web" 보고)라 그 분기는 무용.
- **수정**: `DisplayServer.is_touchscreen_available()`로 분기 — 터치(안드로이드 native + 웹 on phone)면 "Drag to aim · release to throw"만, 데스크탑이면 키보드 힌트 추가. (`title.gd`)
- 검증: 헤드드 브라우저 타이틀 footer 데스크탑 변형 확인.

### P6 — 리듀스모션 / 셰이크 강도 설정 (접근성)
- **발견**: 히트스톱은 **이미 구현돼 있었음**(`game_root.gd:_add_hitstop` — 글로벌 time_scale freeze가 HUD/콤보를 멈춰서 팀이 버리고 만든 stackable·gameplay-scoped 버전). UX 리서치의 "히트스톱 추가" 제안은 **회귀라 미적용**. 게임 주스는 이미 ~90% 상용급(트라우마 셰이크·콤보피치 오디오·앤티시페이션·점수 카운트업·햅틱).
- **추가**: `Session.shake_scale`(Full 1.0 / Low 0.5 / Off 0.0) 영속화 + `_update_shake`가 곱함 + How-To 모달에 토글. 기본 1.0이라 게임플레이 **무변화(no-op)**. (`session.gd`·`game_root.gd`·`title.gd`)
- 검증: 토글 UI 렌더 확인, 파스·테스트 그린.

### P2 — 첫 실행 온보딩 (안전판)
- **갭이었음**: `session.gd`에 first-run 플래그 없음. 유일한 안내가 opt-in How-To 모달(대부분 안 엶).
- **구현(저위험)**: `Session.seen_tutorial` 플래그 + 첫 실행 시 How-To **자동 표시**(1회) + 모달 불투명 패널 stylebox(가독성). 위험한 인게임 ghost-hand 오버레이 대신 기존 모달 활용. (`session.gd`·`title.gd`)
- 검증: 신규 컨텍스트 부팅 시 모달 자동 오픈·깔끔 렌더 확인.

### P10 — ASO / 스토어 (마케팅)
- **ASO 키트**(`aso_store_kit.md`): 제목 `HiteZero: Neon Knife Arcade`, 짧은/긴 설명, 키워드, 로케일 ROI(DE·es-419·pt-BR·JA·FR), 캡션, 프로모 스펙 — 전부 붙여넣기용.
- **캡션 스크린샷**: 4장에 네온 헤더 캡션 번인본 생성(`/tmp/hz_cap/*_cap.png`, 1080×2100, 2:1 비율 내). 적용은 사용자 선택.

### P7 — 성능 (실제 문제 아님으로 확정)
- **진단**: "GPU stall: ReadPixels" 경고는 **헤드리스 Chrome/SwiftShader 에뮬 아티팩트** — grep 결과 게임코드에 readback/clip_children/CanvasGroup/get_image 일체 없음. 젖은바닥 반사는 이미 최적(순수 draw_rect). **실기 무관.**
- 보관: 모바일 2D 퍼프 체크리스트(아틀라스 배칭·clip_children 회피·ETC2 유지 등) 레퍼런스로 둠.

### P4/P8 — 웹 (안전 서브셋 반영)
- **반영**: `manifest.webmanifest`(installable·portrait·fullscreen·maskable 아이콘) + apple/mobile web-app 메타 + `netlify.toml` manifest MIME + 모바일 터치 CSS(overscroll/touch-action). (`store_assets/web/manifest.webmanifest`·`deploy_netlify_polished.sh`·`build_web.sh`)
- 검증: 재빌드 후 publish에 manifest 복사·링크 주입·MIME·터치CSS 전부 확인.

## ⏸ Ready-Spec (리서치 완료, 적용 대기 — 위험/블로커 명시)

### P1 — 세로 긴 화면 프레이밍 (출시 직전 위험으로 보류)
- **현 상태**: `project.godot` aspect 미설정=기본 "keep"=레터박스. 실기(1080×2220)는 bg가 채워 검은 바 없이 정상 — "빈 공간"은 디자인(투척 레인)이지 버그 아님.
- **spec**: `window/stretch/aspect="keep_width"`(mode "viewport" 유지·왜곡 없음·안드로이드 #118153 버그 회피) **+ 배경을 `get_viewport_rect()` 전체로 그리고 보드/캐릭터를 상·하 앵커**. ⚠️ **stretch만 바꾸면 빈 band가 더 커짐** — 레이아웃 작업이 본체. 전역 디스플레이 변경이라 출시 후 v1.1에서 충분 검증하며.

### P4/P8 — 웹 풀 PWA (서비스워커·오프라인·탭게이트·구브라우저가드)
- 현재 셸의 SW는 inert 템플릿(미생성) → **완전 설치형(안드로이드 install prompt)·오프라인은 미완**. iOS A2HS는 manifest로 동작.
- **spec**(리서치 완비): `res://web/shell.html` 커스텀셸로 이관(`$GODOT_CONFIG` 사용) → PWA export(`progressive_web_app/enabled=true`, **`orientation=2`=portrait**; 현재 preset은 1=landscape 오설정) → Godot SW + offline 페이지, iOS 오디오 **탭-투-플레이 게이트**, godot.js 구브라우저 throw 대비 가드, netlify SW no-cache. → `web_pwa_spec.md` 참조.

### P2 — ghost-hand 코치 (v1.1 상위안)
- 자동 모달보다 강한 "show don't tell": 첫 AIMING 진입 시 캐릭터에서 위로 끌리는 고스트 손/궤적 애니 + 강제 첫투척 → 클리어 후 해제. `game_root.gd` 오버레이 + AIMING 진입 게이트. (현재 안전판으로 대체)

### P5 — 프로모 영상
- **샷리스트·스펙 확정**(`aso_store_kit.md`): 15s 가로 1080p, 0-2s 훅(벽튕김 대폭발)→2-6s 드래그 루프→6-10s POW/RED→10-13.5s 보스→엔드카드. YouTube 호스팅·수익화 OFF·피처그래픽 필수.
- **녹화 파이프라인 검증**: 헤드드 webm 녹화 가동 확인. **단, AI 자동플레이는 너무 빨리 game over**해 밀집보드·보스 같은 프리미엄 순간이 안 나옴 → 중간품질 푸티지는 폐기.
- **권장**: 숙련된 사람이 샷리스트대로 **화면녹화**(adb screenrecord / iOS 화면녹화). 키프레임 소재로는 **프리미엄 스틸 4장**(`store_assets/play_screen_1~4.png` = 밀집보드·POW·RED·보스)을 그대로 영상 컷/썸네일에 사용 가능.

### P6 — 잔여 주스 (선택)
- 이미 상용급. 잔여: 고콤보 티어에서 크로매틱/블룸 플래시, 보스/하트로스에 기존 히트스톱 더 무겁게 — 선택적 미세조정.

## ⚠️ Cascade (게임코드 변경 결과 — 사용자 인지 필요)
- 변경 파일: `session.gd`·`title.gd`·`game_root.gd`(게임) + `build_web.sh`·`deploy_netlify_polished.sh`·`manifest.webmanifest`(웹).
- **스크린샷 4장: 재촬영 불필요** — 변경이 인게임 HUD/비주얼 무변(P2/P3 타이틀, P6 기본 no-op). 기존 유효.
- **AAB: 재빌드+재검증 완료** ✅ — 커밋 `450ea2b` → 태그 `v1.0.0` → CI run 27513597341(2m49s) → bundletool split 에뮬 설치·부팅·플레이·폴리싱 렌더(P2/P3/P6)·크래시0 검증. `~/hitezero_release/hitezero-android/hitezero.aab` = 폴리싱 v1.0.0(jar verified, vc1). **제출 준비 완료.**
- **웹: 재배포 필요** — P4/P8 반영 빌드를 라이브로(계정 토큰 대기 중).
- 커밋: 폴리싱분 `450ea2b` 완료. 잔여(47 구파일 삭제 + 이전 untracked)는 별도 housekeeping.
