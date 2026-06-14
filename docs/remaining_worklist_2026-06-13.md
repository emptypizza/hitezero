# HiteZero 잔여 보완사항 (2026-06-13)

> 근거: `docs/hitezero_worklist_plate.png`(6/12 플레이트), `godot/docs/code_review_2026-05-29.md`,
> `gameplay_expansion_plan.md` 우선순위 매트릭스, `arcade_feel_polish_plan.md`,
> `docs/plans/2026-04-22-lightning-rider-godot-rebuild.md` + 금일 코드 grep 재검증.
> 완료 반영: LD-01, VX-01/02/03 (2026-06-12 드롭, dist 빌드 포함).

## A. 플레이트 잔여 — 6/10건

| 코드 | 항목 | 우선 | 공수 | 비고 |
|---|---|---|---|---|
| FL-01 | 모바일 터치·드래그 조준 수동 QA | ●●● | S | progress.md TODO 잔존. 새 빌드로 즉시 가능 |
| LD-02 | 신규 블록 메카니크 (4종 고정 → 후반 신규 위협) | ●●● | L | 쉴드/분열/회복 등. block.gd+generator+HUD |
| LD-03 | 난이도 커브 실측 검증 | ●●○ | S | gameplay_spec.md 대비 체감 대조 |
| LD-04 | 보스 사이클 변주 | ●●○ | M | lv30+ 동일 보스 재등장, 현재 HP 스케일만. 강화 패턴/2페이즈 변형 |
| FL-02 | 발리 중 능동 개입 확장 | ●●○ | M | 패들 바운스 보상 등 — 관전 시간 제거 |
| FL-03 | GameFeel 튜닝 .tres 통합 | ●○○ | M | polish plan 업무7. 매직넘버 산재 해소 + 회귀 테스트 |

## B. 신규 발견 — 기능 갭

| 코드 | 항목 | 우선 | 공수 | 근거 |
|---|---|---|---|---|
| NEW-01 | 인게임 일시정지 부재 | ●●● | S | `pause` 구현 0건 (hud/game_root grep). 모바일·웹 필수 UX — 전화/탭전환 시 런 증발 |
| NEW-02 | SND 음소거 미영속 | ●●○ | S | HUD 핀은 런 단위, `session.gd`에 sound 키 없음 |
| NEW-03 | 업적 시스템 | ●○○ | M | expansion ★12. 통계 카운터는 이미 있어 기반 완료 |
| NEW-04 | 캐릭터 시스템 | ●○○ | L | expansion ★11. 코인 싱크 보강 효과 |
| NEW-05 | 레벨 에디터 빌드 (스코프 재확인) | 판단 필요 | XL | 4/22 리빌드 플랜 산출물 #2 (ONIGIRI 에디터). 이후 게임이 나이프 슈터로 피벗 — 유지/폐기 의사결정부터 |
| NEW-06 | 로컬라이즈 (ko/en) | ●○○ | S | UI 전부 영어 하드코딩 (title.gd 등). 한국어 원작 |

## C. 성능 — code_review P1, 금일 재확인 (여전히 유효)

| 코드 | 항목 | 근거 |
|---|---|---|
| P1-1 | 웹브리지 매 프레임 전체 블록 직렬화 | `game_root._process` → `_update_web_bridge_state()` 무스로틀 |
| P1-2 | `_emit_ui_update` 25개소 호출 + 매 호출 배열 `duplicate()` | game_root.gd:920-923 |
| P1-3 | 충돌 매 프레임 O(나이프×블록) 브루트포스 | `_check_block_collision` 전체 순회. POW 미니나이프 대량 시 최악 |

## D. 유지보수 — P2

- `game_root.gd` 2,217줄 (5/29 리뷰 1,666줄 → +551) — 책임 분리 검토
- `session.submit_score()` 데드코드 제거
- CPU 파티클 고카운트 → GPU 오프로드 여지
- polish plan 업무6: 네온 글로우/블룸 .gdshader + Light2D (FL-03과 별개의 보류 항목)
- `dist/` 구 버전드 zip 2개 정리 (bd905106, eee2e750)

## 추천 다음 배치

1. **FL-01 + NEW-01 + NEW-02** — 전부 S, 출시 체감 직결 (QA는 새 빌드로 바로, pause+mute 영속은 반나절감)
2. 그다음 **LD-02** (콘텐츠 핵심, L) 또는 **P1 성능 3종** (출시 안정성)
3. NEW-05 에디터는 스코프 판정만 먼저 — 만들 거면 별도 트랙

검증 메모: A/B는 문서·코드 교차 확인, C는 금일 grep로 현존 확인. 완료 4건(LD-01, VX-01/02/03)은
헤드리스 테스트 + 팩 부팅까지 통과, dist 반영 완료.
