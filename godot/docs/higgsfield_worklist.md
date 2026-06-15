# HiteZero × Higgsfield — 작업 10 (진행 현황 + 턴키 큐)

> 2026-06-14. Higgsfield 잔액 **0크레딧**(Free). 새 AI 생성은 **업그레이드 전까지 전면 불가**.
> 그래서: **H1·H3는 이미 생성된 자산을 로컬 가공해 실산출물로 완료**, **H2·H10은 결정/거버넌스**,
> **H4~H9는 "업그레이드 즉시 1발" 턴키 사양으로 스테이징**(가짜 생성 없음).
> 통합 원칙: #H3 파이프라인 통과분만 repo 투입, gameplay_spec 계약 불변, Play 출시가 1순위.

---

## ✅ H1 — 배경제거 → 드롭인 검증 (완료, 0cr)
- `cel_rim_A` → `tools/ai_sprite_cleanup.py`(grabcut 배경제거 + 249px + 팔레트48) → 투명 스프라이트 `higgsfield_proofs/maid_clean_249.png` (155×249).
- 목업: `higgsfield_proofs/dropin_mock.png` — 실제 게임 스케일(400×700 로직)·HUD(하트·나이프·별)·7열 블록 그리드(셀 브릭+RED_ENEMY)에 메이드를 앉힘.
- **판정: 통한다.** 메이드+블록+적이 한 게임으로 읽힘. 잔여: grabcut 미세 헤일로(프로덕션은 Higgsfield remove_background 또는 수동 매트로 대체) + 발 피벗 미세조정.

## ✅ H3 — 픽셀 정리 파이프라인 (완료, 0cr)
- `godot/tools/ai_sprite_cleanup.py` — 배경제거(grabcut)·서브젝트 크롭·목표높이 다운스케일·팔레트 양자화·알파 임계화·발 피벗 앵커. 메이드/브릭/적 3종에 작동 확인.
- 사용: `python3 tools/ai_sprite_cleanup.py IN OUT --height 249 --remove-bg --colors 48 [--canvas-w 167]`
- **모든 후속 통합(H5·H6)의 전제 도구.** repo 투입 직전 단계 자동화.

## ✅ H2 — 렌더모델 통일 결정 (완료, 0cr)
- 증거(전면전환 테스트): 메이드 = **플랫 2D 애니 셀**, 브릭·적 = 광택 3D셀 → 미세 불일치.
- **결정: 플랫 2D 애니 셀로 통일.** 근거: (1) 픽셀게임 NEAREST와 충돌 최소 (2) 32~120px 소형에서 광택 3D 디테일은 낭비 (3) 메이드 기준에 블록을 맞추는 게 캐릭터 재생성보다 쌈.
- **스타일 락 프롬프트**(블록·적 재생성 시 접미):
  `flat 2D anime cel style, thin clean ink outline, 2-3 tone banded shading, NO glossy 3D specular, NO photoreal reflection, matte, warm rim light, dark neon bg`
- 적용 대상: H6(적·보스), H9(배경), 필요시 H7 스토어 컷. 메이드(H5)는 이미 이 톤.

---

## ⏸ H4~H9 — 턴키 스테이징 (업그레이드 시 즉시 실행 / 0cr 불가)
> 실행 전제: PLUS $49=1000cr 또는 ULTRA $99=3000cr. 1패스 총량 추정 **약 120~180cr**(아래 합).
> 각 항목은 MCP 호출 사양 그대로 — 크레딧 생기면 복붙 발사.

### H4 — Soul 캐릭터 학습 (전제, ~17cr)
- 호출: `show_characters(action="train", name="HiteZero Maid", type="soul_2", images=[<maid 프레임 5~20장 media_id>])`
- 레퍼런스: `godot/assets/textures/player/maid/` 의 idle_0..4 · attack_0..4 · combat_idle · run_0..5 중 8~12장 업로드(media_upload→PUT→media_confirm).
- 산출: `soul_id` → H5의 모든 포즈를 **동일 캐릭터**로 고정(드리프트 차단).
- 검증: 학습 후 임의 포즈 3장 → 얼굴·리본·앞치마 동일성 육안.

### H5 — 프레임셋 생성 (~40~60cr, Soul 필요)
- 호출: `generate_image(model="soul_2", params={soul_id, prompt, aspect_ratio:"2:3", count:4})` × 포즈군
- 프롬프트(공통 접미 = H2 스타일락):
  - idle 6~8: `maid idle breathing pose, subtle weight shift, front view`
  - attack wind-up: `maid winding knife back over shoulder, anticipation pose`
  - attack follow-through: `maid arm extended after knife throw, follow-through`
  - run 보강: `maid mid-run stride, dynamic`
- 후처리: 각 출력 → `ai_sprite_cleanup.py --remove-bg --height 249 --canvas-w 167` → `assets/textures/player/maid/`에 동일 네이밍 교체/추가 → `player.gd`의 `TEX_*_FRAMES` 배열만 갱신(계약 함수·피벗 불변) → `tools/test_player_output_vfx.py` 통과 확인.

### H6 — 적·보스 변주 (~20cr)
- `generate_image(model="nano_banana_pro", medias=[red_enemy ref], prompt=...+H2스타일락)`
- RED_ENEMY: **bright red 고정·둥근 실루엣 유지**(`test_red_enemy_sprite.py` red-first·실루엣 규격 통과 필수). 보스: 큰 실루엣 1종.
- 후처리: 적은 32px·블록은 ~57px 게임크기로 정리(소형이라 디테일 절제 = H2 결정과 일치).

### H7 — 스토어 그래픽 셀룩 재생성 (~16cr)
- 피처 1024×500 / 아이콘 / 스샷 보강 2장을 셀 키아트로. 아이콘은 `play_icon_512` 기반 일관.
- 산출 → `store_assets/` 갱신(Play 등록정보 강화). 현 자산도 규격 통과 상태라 **선택적**.

### H8 — 15초 프로모 영상 (~30~60cr, 영상이 비쌈)
- `models_explore(action="recommend", type="video", input="image")`로 최신 영상모델 확인(Kling/Veo/Seedance).
- 입력: H5 캐릭터 컷 + `store_assets/play_screen_*` . 컷: 타이틀 → 콤보 → 적 처치 → 보스(세로 9:16, 15s).
- 산출: Play "프로모 동영상"(전환율↑) + itch 트레일러.

### H9 — 셀룩 배경 변주 (~8cr)
- `generate_image` 네온 아레나 배경을 H2 플랫셀 톤으로. **캐릭터 가독성(분리) 최우선** — 배경이 너무 밝으면 캐릭터 묻힘(H1에서 확인된 리스크).
- 산출 → `godot/assets/textures/bg/` 갱신, 다운스케일 정리.

---

## ✅ H10 — 크레딧·스코프 거버넌스 (완료, 0cr)
- **크레딧 장부**: 시작 10 → 증명 생성 8(maid 2장+brick+enemy, 각 2cr) → **현재 0**. 1패스 완주 추정 120~180cr → **PLUS $49(1000cr) 1개월이면 충분**(돈은 사용자 결정).
- **"완료(done)" 정의**: H1 룩 승인 + H5 프레임셋이 `test_player_output_vfx.py` 통과 + 실기/웹에서 메이드가 블록과 한 화면에 깨짐 없이 = 끝. 그 외(보스·영상·배경)는 "있으면 좋은" 2.x 범위.
- **기회비용**: hitezero **Play 출시가 1순위**(AAB·제출 답안 준비됨). 아트 대개혁이 출시를 밀면 트리아지 역전 — **출시 그린 후 H4~H9 착수** 권장.
- **통합 게이트**: AI 산출물은 #H3 파이프라인 통과 + gameplay_spec 계약(로직 상수·NemoInput 격 player.gd 피벗) 불변 + 테스트 그린일 때만 repo 투입. 라이브 깨면 안 됨.

---

## 다음 트리거
1. (지금) H1 드롭인 룩 OK인지 사용자 승인 → 렌더모델(H2 플랫셀) 확정.
2. 크레딧 충전 시 → H4 Soul → H5 프레임셋(파이프라인 통과) → repo 투입·테스트.
3. 출시 끝나고 여유 → H6·H8·H9.
