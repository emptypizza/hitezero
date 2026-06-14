# HiteZero × Higgsfield Game MCP — 적용 계획 (2026-06-13)

> 목적: ANIM-01 자아비판에서 나온 **캐릭터 비주얼 약점**(입체감 부족 · 림라이트
> 부재 · 캐릭터↔블록 아트 불일치 · 와인드업 프레임 부재 · 필터 혼용)을 Higgsfield의
> 생성 역량으로 메운다. 비주얼 산출물만 다루며 **NemoInput 조준/발사 계약·세이브
> 호환성은 불변**(생성된 건 스프라이트 교체일 뿐, 코드 계약은 그대로).

## 0. 전제 — 연결 상태

- Higgsfield MCP은 Cowork에서 연결 가능하나 **현재 미연결**(커넥터 레지스트리 미등재
  → 커스텀 커넥터로 직접 추가). 서버 URL: `https://mcp.higgsfield.ai/mcp`.
- 연결 전까지는 Higgsfield 웹앱/Soul로 수동 산출 → repo 파이프라인 투입도 동일하게
  성립. MCP 붙으면 아래 각 단계가 도구 호출로 자동화된다.
- 역량(2026-06 기준): 이미지 ≤4K, 영상 ≤15s, **Soul = 캐릭터 일관성 학습**,
  30+ 모델(Soul·Cinema Studio·Flux·Seedream·Kling·Veo 등), 텍스트/레퍼런스/혼합 입력.

## 1. 왜 Higgsfield인가 (약점 → 역량 매핑)

| 자아비판 약점 | Higgsfield 역량 | 산출물 |
|---|---|---|
| 캐릭터↔블록 아트 불일치 (최우선) | img2img + 스타일 레퍼런스 | 셀-통일 메이드 리텍스처 |
| 배경에 묻힘 / 림라이트 부재 | 라이팅 프롬프트 + 4K | 림라이트 들어간 캐릭터 시트 |
| 와인드업/예비동작 프레임 없음 | Soul 일관 캐릭터 + 포즈 생성 | 신규 anticipation·follow-through 프레임 |
| 던지기/idle 프레임 부족·뻣뻣 | Soul 멀티포즈 시트 | 확장된 idle/attack/run 프레임셋 |
| 스토어 전환(프로모 영상 없음) | 이미지→비디오(Kling/Veo) | 15s 게임플레이 트레일러 |

## 2. 적용 항목 (우선순위 = 효과/비용)

### A. Soul 캐릭터 학습 — *모든 후속의 전제* (먼저)
- 입력: 기존 메이드 시트 전체(`assets/textures/player/maid/*.png` — idle/attack/run/
  combat_idle/back/gameover)를 학습 레퍼런스로.
- 산출: "HiteZero Maid" Soul 토큰. 이후 모든 신규 포즈가 **같은 캐릭터**로 일관 생성
  → AI 캐릭터 드리프트(매 생성마다 얼굴/의상 달라짐) 차단.
- 검증: 학습 후 임의 포즈 3장 생성해 얼굴·리본·앞치마 동일성 육안 확인.

### B. 셀-통일 + 림라이트 리텍스처 — *최우선 비주얼 갭*
- 입력: combat_idle + idle 프레임. 스타일 레퍼런스 = 우리 셀-슬랩 블록 렌더
  (`outputs/cel_25d_enemies_preview.png`)와 `rounded_block.gdshader`의 룩(잉크 외곽선·
  밴드 음영·따뜻한 림).
- 프롬프트 방향: "anime maid, **cel-shaded with thin ink outline + banded shading**,
  **warm rim light separating her from a dark neon background**, pastel→slightly
  saturated, crisp pixel-art friendly, transparent background".
- 산출: 림라이트 + 셀 외곽선 입힌 메이드 베이스. → 블록과 같은 렌더링 언어로 통일.

### C. 애니 프레임 보강 (부드러움 + 예비동작)
- Soul로 다음을 생성: **wind-up(뒤로 당김) 1–2프레임**, attack follow-through,
  idle 6–8프레임(호흡), run 보강. 던지기에 진짜 예비동작 포즈가 생기면 ANIM-01의
  절차적 스쿼시가 *흉내내던* 부분을 실제 프레임이 대체.
- 비고: player.gd의 절차적 리그(호흡·스쿼시·기울임)는 유지 — 프레임이 좋아지면
  리그는 그 위에서 더 자연스러워진다(상호보완).

### D. 스토어 프로모 영상 15s (Play CVR)
- 입력: 우리 스크린샷(`store_assets/play_screen_*.png`) + 신규 캐릭터 컷.
- 모델: 이미지→비디오(Kling/Veo). 컷: 타이틀 → 콤보 연출 → 적 처치 → 보스.
- 산출: 세로 15s 트레일러. Play Console "프로모 동영상"(전환율에 스샷보다 큼).

### E. (옵션) 적/보스/배경 변주
- 적 블롭·보스 실루엣 변주, 스테이지 배경 변형. 단 RED_ENEMY는 red-first·실루엣
  보호 테스트(`test_red_enemy_sprite.py`) 통과 규격 유지.

## 3. repo 파이프라인 투입 (생성물 → 게임)

1. Higgsfield 출력 = **투명 PNG**, 캐릭터는 동일 **캔버스 비율·발 피벗**으로 정렬
   (기존 maid 프레임과 앵커 일치해야 player.gd가 안 흔들림).
2. **픽셀 정리**: AI 출력은 안티앨리어싱이 섞이므로 → 목표 해상도로 다운스케일 +
   인덱스 팔레트/도트 정리(필요 시 Aseprite). 블록이 NEAREST라 캐릭터도 픽셀-크리스프로
   통일(ANIM-01 필터 혼용 지적 해소).
3. 배치: `assets/textures/player/maid/`에 같은 네이밍으로 교체/추가.
4. 코드: 프레임 추가 시 `player.gd`의 `TEX_IDLE_FRAMES`/`TEX_ATTACK_FRAMES` 배열 +
   `IDLE_FRAME_ORDER`만 갱신. 계약 함수(`play_output`)·피벗 불변.
5. 검증: `tools/test_player_output_vfx.py`(프레임 파일 존재·attack 프레임 사용) +
   `--import` 후 headless 스모크 + 육안. 세이브 포맷 무관(비주얼만).

## 4. 리스크 / 가드레일

- **픽셀 그리드 불일치**: AI 생성물이 기존 도트와 안 맞을 위험 → 항상 다운스케일+정리
  단계 필수. 정리 안 한 4K를 그대로 넣지 말 것.
- **캐릭터 드리프트**: 반드시 A(Soul) 먼저. 단발 img2img 반복은 얼굴이 매번 바뀜.
- **상업/라이선스**: Play 유료 배포 → Higgsfield 생성물의 상업 사용권·모델별 약관
  확인(특히 영상 모델). 학습 레퍼런스는 우리 자산만.
- **스코프 크리프**: 이건 hitezero 비주얼 트랙 *연장*이다. Nemo_DO·pubgidle 정지
  비용 계속 누적 — 영상(D)까지만 하고 멈추는 게 출고 우선.

## 5. MCP 연결 시 실행 순서 (자동화)

1. Cowork에서 Higgsfield MCP 연결(`higgsfield.ai/mcp`) → 도구 노출 확인.
2. `train character`(Soul) ← maid 시트 업로드 → 토큰 확보 (항목 A).
3. `generate image`(레퍼런스=블록 셀룩) → 림라이트·셀 통일 베이스 (B).
4. `generate image`(Soul 토큰) → wind-up/idle/attack 프레임 (C).
5. 픽셀 정리 → repo 투입 → 테스트 (§3).
6. `generate video`(image→video) → 프로모 트레일러 (D).

## 핸드오프
- 생성·연출 방향: juice-smith (셀 통일 + 림라이트 톤, 프레임 안무).
- 파이프라인·검증: tech-lead (피벗 정렬, 픽셀 정리 자동화, 테스트).
- 스코프 게이트: producer (D까지 끊고 출고 복귀 판정).

## 즉시 가능한 첫 스텝
MCP 연결만 해주면 **A(Soul 학습) → B(셀 통일 + 림라이트)** 부터 돌린다 — B가 ANIM-01
최우선 약점(아트 불일치·림라이트)을 직접 때린다.
