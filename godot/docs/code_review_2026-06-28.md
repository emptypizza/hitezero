# hitezero 코드베이스 종합 분석 + 보완 로드맵 (2026-06-28)

> 다중 에이전트 분석(80 agents · 5영역 이해 + 5차원 리뷰 + 적대적 검증).
> 발견 69건 → **검증 통과 55건** (critical/high 0 · medium 12 · low 43).
> **P0 2건(보스 데미지·페이즈 점프)은 본 커밋에서 수정 완료 → v1.0.2.**

---

# hitezero 기술 보완 로드맵

> 검증 통과 55건을 영향도×노력으로 재정렬한 실행 계획. 라인 번호는 **이 워크트리 브랜치(`claude/clever-black-4a7da5`, game_root.gd 2532줄·boss.gd 805줄, boss_system.gd 미존재)** 기준으로 재확인했다. 원 발견 다수가 인용한 `boss_system.gd`/`vfx_system.gd` 경로는 이 브랜치에 **없으므로**, 보스/VFX 관련 항목은 전부 `game_root.gd`·`boss.gd` 인라인 코드가 실제 수정 대상이다.

---

## 1. 종합 진단

hitezero는 단일 오케스트레이터(`game_root.gd`)가 컨트롤러·시뮬레이션·렌더러·연출·웹브리지를 모두 겸하는, 기능적으로는 완성도 높은 캐주얼 아케이드다. 수동 결정론 물리, 절차적 SFX, 디바운스 세이브, soft-pause, 콤보/런 모디파이어 스케일링 등 코어 루프는 견고하게 동작하며 Android CI 서명 빌드도 자동화돼 있어 **출시 자체는 가능한 상태**다. 그러나 (a) **보스전이 모든 데미지 빌드를 무시**(#1)하고 페이즈를 건너뛰면 셋업이 영구 누락(#2)되는 두 건의 실제 정확성 버그, (b) BGM 전무·게임오버 풀리셋·온보딩 부재 같은 **상용 첫인상/리텐션 갭**, (c) 2532줄 단일 파일에 응집된 구조 부채가 약점이다. 보안·데이터 손실급 critical은 없고 대부분 발견이 medium↓로 하향 검증됐다. **결론: P0 2건(보스 버그)만 고치면 출시 차단 요소는 해소되며, BGM·게임오버 UX·접근성 게이트가 평점을 좌우할 폴리시 레버다.**

---

## 2. 즉시 수정 (P0) — 출시 전 필수

게임플레이 정확성을 깨는 실제 버그. 둘 다 `boss.gd`/`game_root.gd` 인라인 수정으로 1시간 내 처리 가능.

| # | 위치 | 한줄 액션 |
|---|------|-----------|
| **#1** 보스 데미지 1 하드코딩 | `boss.gd:129` `func take_hit(hit_pos)`, 호출부 `game_root.gd:1754` | `take_hit(hit_pos, damage:=1)`로 인자 추가, 내부 `dmg = damage * (2 if weak else 1)`로 변경, 호출부를 `take_hit(knife.position, _get_knife_damage())`로 교체. `hit_mirror_block`/`take_spawner_shield_hit`/`hit_split_segment`도 동일 인자화. → 레벨업 DAMAGE·그룹킬 스택·2x 버프가 보스에 적용됨 |
| **#2** 페이즈 점프 시 중간 셋업 영구 누락 | `boss.gd:196-205` `_check_phase_transition` | `phase = new_phase` 직접 점프를 `while phase < new_phase: phase += 1; _on_phase_change(); phase_changed.emit(phase)` 순차 전이로 교체. SPLITTER가 phase2 세그먼트를 건너뛰어 승리판정(`are_segments_alive`)이 어긋나는 케이스 제거 |

이 두 개는 같은 함수 체인(`take_hit → _check_phase_transition → _on_phase_change`)을 건드리므로 **한 PR로 묶어** 보스 5종(MIRROR/SPAWNER/SPLITTER/TIMEWEAVER/일반) 각각 약점 명중·2x버프·약점없이 동시다발 명중 시나리오를 수동 검증한다.

> 문서 동기화도 P0에 포함: `gameplay_spec.md:39`가 게임오버를 "현재 레벨 재시작"이라 적었으나 실제는 풀 런 리셋(#33). spec을 실제 동작에 맞춰 1줄 수정.

---

## 3. 단기 개선 (P1) — 코드 건강 / 성능 / UX

### P1-A. 접근성 게이트 (출시 평점 직결, 광과민 위험)
- **#36 reduce-motion이 HUD를 게이트하지 않음** — `hud.gd`의 `set_loops` 무한 점멸 2곳(GAME OVER `NEW BEST`, 보스 `WARNING`)이 광과민 위험. 최소한 이 둘은 `Session.shake_scale <= 0`일 때 스킵. 가능하면 `_punch_scale`/`_heart_flash`/`_pill_flip`/토스트 슬라이드 진입부에 동일 게이트 추가. **+ 토글 라벨을 'Screen Shake' → 'Reduce Motion'으로 변경**(title.gd:265)해 기대-실제 갭 해소.
- **#35 터치 타겟 24px** — `hud.gd:913` `_make_pill_button`의 높이 24px를 `custom_minimum_size` 36px 이상으로, 또는 투명 히트영역 44px 확장. 일시정지(II) 버튼 우선. (가로 간격 16px는 이미 충분 — 세로축만 손보면 됨)

### P1-B. 콘텐츠 폴리시 (상용 첫인상)
- **#34 BGM 전무** — `audio_manager.gd`에 음악 전용 버스 + 루프 `AudioStreamPlayer` 추가, title/play/boss 상태별 크로스페이드. 절차적 신스 또는 무료 칩튠 2~3트랙. mute와 별개 'Music on/off'. 저비용·고임팩트.
- **#33 게임오버 풀리셋** — `game_root.gd:416` GAME_OVER 탭 → 무조건 `_start_new_run()`. 게임오버 화면에 '최고 도달 스테이지' 표시 + 코인 소비 무료 부활(하트1) 또는 1~2스테이지 앞 소프트 컨티뉴. v1.1 광고 부활을 기다리지 말 것.

### P1-C. 성능 정리 (모바일/웹 프레임 안정)
하나의 "엔티티 풀링 + 매-프레임 낭비 제거" 작업으로 묶음:
- **#3/#9/#23 칼 풀링 부재 (3건 병합)** — `deactivate()` 시 풀 큐 반환, `_spawn_knife`가 풀 우선 재사용. 순회 루프(`_update_knives`/`_check_win_lose`/`_draw_wet_reflections`)는 `get_children()` 대신 active 배열 순회. configure/deactivate 인터페이스가 이미 풀링 전제이므로 풀만 연결.
- **#3 player 대기칼 매-프레임 재생성** — `player.gd:128` `set_waiting_knives`에 `_prev_count`/`_prev_visible` early-return 가드. (AIMING에서 초당 수백 노드 churn 제거, 5분 작업)
- **#10/#20 Array[Dictionary] 파티클** — 빈도 높은 `vfx_particles`/`coin_shards`만 PackedVector2Array+PackedFloat32Array 병렬배열 또는 RefCounted struct로 전환 + **하드캡(vfx 120개)** 추가. 콤보 스파이크 프레임타임 평탄화.
- **#13/#14 player/block 매-프레임 풀 재계산** — `texture.get_size()`+scale fit을 텍스처 변경 시에만, `base_scale`을 configure 시 1회 캐시. block은 `flash<=0 && squash<=0 && !(RED_ENEMY active)`면 조기 return + `set_process(false)` 토글.

### P1-D. CI/빌드 견고성 (릴리스 신뢰성)
- **#46 서명 미검증** — `android.yml` export 직후 `apksigner verify --print-certs` / `jarsigner -verify -strict` + 디버그 인증서(`CN=Android Debug`) grep 가드, 실패 시 exit 1.
- **#47 version/code 수동** — CI에서 `sed`로 `GITHUB_RUN_NUMBER` 주입, 빌드 후 원복. 재제출 충돌 방지.
- **#51 Release 미첨부** — v* 태그 시 `softprops/action-gh-release`로 AAB/APK + sha256 자동 첨부 (90일 만료로 산출물 소실 방지).
- **#52 sed in-place** — `trap 'sed -i ...export_format=1...' EXIT`로 원복 보장.

---

## 4. 중기 과제 (P2) — 리팩토링 / 수익화 / 리텐션

### P2-A. game_root.gd 분할 (구조 부채의 근원, 2532줄)
점진적 추출. 의존도 낮은 순서로:
1. **VFX/Cosmetic 추출** — `_draw_wet_reflections`/`_draw_block_depth`/파티클/배경/반딧불(대략 1085~2532줄, 파일의 절반)을 `VFXDirector` 노드로. (다른 브랜치엔 이미 `vfx_system.gd`로 분리돼 있음 — **머지 정합성 먼저 확인**)
2. **ScreenEffects 추출** — trauma²/hitstop/flash + `_freeze_frame`/`_kick_world` shim 제거(#25/#32). 시간모델을 단일 수동 스케일축으로 통일.
3. **ComboSystem/ItemSystem 추출** + Boss 충돌을 `try_hit(knife)->HitResult` 인터페이스로 옮겨 `_bounce_knife` 반사 헬퍼 1개 추출(#18 — 현재 블록+보스 5곳 복붙).
4. **명시적 상태머신** — `_enter_state(next)` 단일 전이 함수로 진입 초기화 집중(#24).

### P2-B. 견고성 / 데이터
- **#6/#30 세이브 무결성** — `save.tmp` 쓰기 후 `DirAccess.rename` 원자교체 + `save.bak` 폴백, load 시 `clampi`/`maxi` 검증, `version` 키. (싱글플레이라 변조방어는 불필요 — 손상복구만)
- **#5/#29 칼 터널링** — 이동량 > radius이면 `ceil(len/radius)` 서브스텝 분할. 2x+속도스택+저프레임 코너케이스. (60fps 정상플레이는 무해하므로 P2)
- **#26 통계 직접 mutate** — `Session.record_block_destroyed()` 메서드 경유로 `_mark_dirty` 일관성 회복.

### P2-C. 리텐션 / i18n (마케팅 투자 선행 조건)
- **#38 i18n** — 문자열 `tr()` 추출, EN/KR + ASO 타깃 1~2개. **ASO 다국어 출시 전 필수** (스토어 메타만 번역하고 본문 영어면 전환 무너짐). 본문 최소 8~9px, CJK 폰트 폴백.
- **#33+#41 리텐션 훅** — 데일리 로그인 스트릭(`Session`에 `last_login_day`/`streak` 키), Stats→업적 뱃지 확장. coins→upgrade 루프(~56,900코인)만으로는 소진 후 동기 소멸.
- **#42 온보딩** — 아이템/보스 첫 조우 시 1회성 설명 토스트 + `seen` 플래그. 첫 MIRROR 보스 좌절 완화.
- **#39 반응형 레이아웃** — HUD 절대좌표 → 앵커/컨테이너, `stretch aspect=keep_width`, safe-area 마진. (팀이 polish_worklist에서 인지·연기한 항목, portrait 고정이라 긴급도 낮음)

---

## 5. 빠른 성과 (Quick Wins) — 30분 내, 고가치

| 작업 | 위치 | 효과 |
|------|------|------|
| **player 대기칼 early-return 가드** | `player.gd:128` `set_waiting_knives` 진입부에 `_prev_count`/`_prev_visible` 비교 후 return | AIMING 중 초당 수백 Sprite2D churn 즉시 제거 (#3) |
| **광과민 점멸 게이트** | `hud.gd`의 `set_loops` 점멸 2곳(NEW BEST·보스 WARNING)을 `if Session.shake_scale > 0:`로 감쌈 | 접근성 실효 + 평점 리스크 차단 (#36) |
| **죽은 코드 + shim 제거** | `boss.gd`의 `get_weak_point_pos`/`get_all_hitboxes`/`_are_mirrors_alive`, `knife.gd` `speed()`, 빈 `_draw_hp_text()` 호출 2곳 삭제 | ~25줄 정리, `--headless --check`로 회귀확인 (#19) |
| **콤보 룩업 단일화** | `game_constants.gd`에 static `combo_tier(hit)`/`combo_multiplier(hit)` 추가, game_root·hud 3중 중복 제거 | off-by-one 인덱싱 회귀위험 제거 (#31) |
| **eyebrow에서 'Godot' 제거 + spec 문서 수정** | `title.gd:65` `"HiteZero Godot"`→`"HiteZero"`, `project.godot:17` config/name, `gameplay_spec.md:39` 게임오버 설명 | 엔진명 노출 제거(아마추어 인상) + 코드-문서 정합 (#40/#33) |

---

## 우선순위 요약

```
출시 차단:   P0 #1, #2 (보스 데미지·페이즈) — 1시간, 1 PR
평점 레버:   P1-A 접근성(#36/#35) + P1-B BGM(#34)·게임오버(#33)
프레임 안정: P1-C 풀링/파티클/매-프레임 낭비 병합 (#3/#9/#10/#13/#14/#23)
릴리스 위생: P1-D CI 검증 4건 (#46/#47/#51/#52)
구조 부채:   P2-A game_root 분할 (다른 브랜치 vfx_system 머지 정합 먼저)
```

**병합된 중복 발견:** 칼 풀링 #3↔#7↔#9↔#23 (4→1), Array[Dictionary] #10↔#20 (2→1), 터널링 #5↔#29 (2→1), 세이브 #6↔#30 (2→1), 포커스아웃 일시정지 #4↔#17↔#43 (3→1, P2 폴리시), shim #25↔#32 (2→1), 보안헤더/CSP #44↔#45 (2→1).

**검증 정정 메모:** 원 발견의 라인 번호와 파일 경로가 광범위하게 stale(특히 `boss_system.gd`/`vfx_system.gd` 참조는 이 브랜치에 없음). 위 표의 라인은 현재 워크트리에서 재확인한 값이며, 실제 수정 시 `grep -n "func <name>"`로 한 번 더 확인 권장.

---

## 부록 — 검증 통과 발견 55건 전체

### medium (12건)
- **[correctness]** 보스 본체 데미지가 1로 하드코딩 — 모든 데미지 업그레이드/버프 무효 — `godot/scripts/boss.gd:129-142` (확신:high)
- **[correctness]** 보스 페이즈 점프 시 중간 페이즈 셋업 영구 누락 (Splitter/Spawner 치명) — `godot/scripts/boss.gd:196-245` (확신:high)
- **[perf-mobile]** 칼 노드 풀링 부재 — 매 발사 instantiate, 비활성 칼이 컨테이너에 누적 — `godot/scripts/game_root.gd:497-513, 515-516, 800-804, 1045-1048` (확신:high)
- **[perf-mobile]** Array[Dictionary] 기반 파티클 시스템 — 매 프레임 dict 박싱 + float() 캐스팅 누적 — `godot/scripts/game_root.gd:2072-2089, 2159-2172, 2385-2422, 2503-2517, 1556-1589` (확신:high)
- **[quality]** 칼 노드 풀링 부재 — configure/deactivate 인터페이스가 풀에 연결되지 않음 — `godot/scripts/game_root.gd:497-513, 1045-1048` (확신:high)
- **[quality]** _check_block_collision이 첫 충돌 1개만 처리하고 return — 고속 칼 터널링 + step() CCD 없음 — `godot/scripts/game_root.gd:591-648, 515-525` (확신:high)
- **[gamedesign-ux]** 게임오버 시 무조건 1스테이지부터 재시작 — 진행감/리텐션 핵심 갭 — `godot/scripts/game_root.gd:416-418, 320-388` (확신:high)
- **[gamedesign-ux]** 배경음악(BGM) 전무 — 상용 아케이드 첫인상/몰입의 큰 결손 — `godot/scripts/audio_manager.gd:34-47` (확신:high)
- **[gamedesign-ux]** 인게임 핵심 컨트롤(x2·음소거·일시정지) 터치 타겟이 최소 권장치 미달 — `godot/scripts/hud.gd:909-917, 546-562` (확신:high)
- **[gamedesign-ux]** reduce-motion(Screen Shake Off)이 HUD 연출 전체를 게이트하지 않음 — 불완전한 접근성 — `godot/scripts/hud.gd:95-107, 144-186, 746-786` (확신:high)
- **[gamedesign-ux]** 전 텍스트 영어 하드코딩 + 6~8px 픽셀폰트 — i18n 미지원이 ASO 다국어 전략과 충돌 — `godot/scripts/hud.gd:390, 815; title.gd:81,164` (확신:high)
- **[build-sec]** CI가 서명 산출물(AAB/APK)을 검증하지 않음 — 잘못된/디버그 서명이 조용히 통과 — `.github/workflows/android.yml:95-119` (확신:high)

### low (43건)
- **[correctness]** player.set_waiting_knives가 매 프레임 대기칼 노드 전체 free+재생성 — `godot/scripts/player.gd:128-131, 323-343`
- **[correctness]** focus-out 자동 일시정지가 STAGE_CLEAR/GAME_OVER 코루틴 진행 중 화면을 멈추지 못함(또는 의도와 충돌) — `godot/scripts/game_root.gd:286-312, 842-911`
- **[correctness]** 고속 칼 터널링 — 단일 점(point) 충돌 + 첫 블록만 처리 후 return — `godot/scripts/game_root.gd:515-572, 591-648`
- **[correctness]** 세이브 손상/무결성·검증 부재 — load 실패 시 전 진행도 조용히 0 초기화 — `godot/scripts/session.gd:77-133`
- **[correctness]** 칼 노드 풀링 부재 — 비활성 칼이 Knives 컨테이너에 누적 — `godot/scripts/game_root.gd:497-513, 565-567`
- **[correctness]** _spawn_mini_knife가 block.position(레이어-로컬)과 global_position을 혼용해 미니칼 시작 위치 불일치 가능 — `godot/scripts/game_root.gd:643-646, 683-687`
- **[perf-mobile]** rounded_block.gdshader가 TIME(foil glint)을 써 모든 블록 스프라이트가 상시 재드로우 강제 — `godot/assets/shaders/rounded_block.gdshader:28-29, 63-66`
- **[perf-mobile]** bg.png 1024×1536 무압축(compress/mode=0, mipmaps off) — VRAM/대역폭 낭비 — `godot/assets/textures/bg/bg.png.import:compress/mode=0`
- **[perf-mobile]** player.gd _process가 매 프레임 텍스처 스왑 + get_size + scale fit + filter sync를 무조건 수행 — `godot/scripts/player.gd:91-98, 169-196`
- **[perf-mobile]** block.gd가 살아있는 모든 블록에서 매 프레임 _process + sprite scale/modulate 재계산 — `godot/scripts/block.gd:69-75, 225-238`
- **[perf-mobile]** knife.step()이 매 프레임 trail 포인트 2개 append + 매번 queue_redraw + to_local 반복 드로우 — `godot/scripts/knife.gd:44-52, 82-99`
- **[perf-mobile]** 오디오 11종 파형을 부팅 _ready에서 동기 합성 — 저사양 기기 첫 프레임 히치 — `godot/scripts/audio_manager.gd:20-46`
- **[perf-mobile]** NOTIFICATION_WM_WINDOW_FOCUS_OUT 자동 일시정지가 모바일에서 의도치 않게 자주 트리거될 소지 — `godot/scripts/game_root.gd:306-312`
- **[quality]** 보스 충돌의 knife 반사 코드 4~5회 복붙 — 헬퍼 미추출 — `godot/scripts/game_root.gd:634-638, 1695-1702, 1715-1724, 1737-1743, 1769-1779`
- **[quality]** 죽은 코드: 호출자 없는 public 함수 4개 + 빈 스텁 — `godot/scripts/boss.gd:149-151, 161-178, 334-338, 803-805`
- **[quality]** 엔티티 서브상태가 Array[Dictionary] + 매 프레임 float()/int() 캐스팅 — 타입 안전성·성능 손실 — `godot/scripts/boss.gd:29, 44, 48, 167-177, 415-431, 449-459`
- **[quality]** game_root가 Boss의 private 멤버 _mirror_blocks에 직접 접근 — 캡슐화 위반 — `godot/scripts/game_root.gd:1683-1689`
- **[quality]** 패들 클램프 마진 20.0, 트레이 두께 14.0, base_score 100, 보스 점수 15/20 등 매직넘버 산재 — `godot/scripts/game_root.gd:409, 425, 432, 542, 710, 1074, 1735, 1763`
- **[quality]** 상태머신이 암묵적 int + 산재한 if/match — enter/exit 훅 부재로 진입 초기화가 함수마다 수동 중복 — `godot/scripts/game_root.gd:453-459, 816-833, 877-884, 1325-1343, 1808-1820`
- **[quality]** 두 시간 시스템(Engine.time_scale vs 수동 sim_delta/hitstop) 공존으로 추론 난이도 상승 — `godot/scripts/game_root.gd:180-218, 893-901, 1934-1949`
- **[quality]** Session 전역 결합 + 게임플레이 통계 직접 mutate가 디바운스 세이브와 어긋남 — `godot/scripts/game_root.gd:730-735, 826, 1826-1827`
- **[quality]** 일관성 없는 노드 해제: clear_level_nodes는 free() 즉시, 나머지는 queue_free() 지연 — `godot/scripts/game_root.gd:271-274, 737, 1047, 1671-1673`
- **[quality]** HUD 연출 tween을 매번 새로 만들고 이전 것을 kill하지 않음 — 빠른 연속 갱신 시 글리치 소지 — `godot/scripts/hud.gd:746-752, 755-760, 776-787, 896-904`
- **[quality]** 세이브 무결성/검증 부재 — 손상 시 조용히 전 진행도 0, 변조 무방비 — `godot/scripts/session.gd:77-103, 106-132`
- **[quality]** _get_combo_multiplier / _get_combo_tier가 동일 룩업 로직을 game_root·hud에 3중 중복 — `godot/scripts/game_root.gd:1481-1495`
- **[quality]** 마이그레이션 shim 함수(_kick_world, _freeze_frame)가 죽은 인자를 받으며 의미와 어긋남 — `godot/scripts/game_root.gd:922-931, 1934-1938`
- **[gamedesign-ux]** 색상만으로 블록 타입을 구분 — 색약 대응 부재 — `godot/scripts/game_constants.gd:36-43, 78-94, 122-128`
- **[gamedesign-ux]** 고정 400x700 절대좌표 레이아웃 + aspect 미설정 → 다양한 폰 비율에서 letterbox/UI 어긋남 — `godot/project.godot:30-33`
- **[gamedesign-ux]** 인게임 타이틀 'Meteor Knife Guard'가 스토어 브랜드 'Neon Knife Arcade'와 불일치 — `godot/scripts/title.gd:65, 73, 81`
- **[gamedesign-ux]** 데일리/스트릭/업적 등 세션 간 복귀 훅 부재 — 단발 베스트스코어 외 돌아올 이유 없음 — `godot/scripts/title.gd:96-157`
- **[gamedesign-ux]** 새 아이템/보스 능력에 인게임 설명·티칭 모먼트 없음 — 학습은 시행착오 의존 — `godot/scripts/game_root.gd:1595-1602, 2316-2326`
- **[gamedesign-ux]** 포커스 아웃 자동 일시정지가 헤드리스 외 모든 환경에 적용 — 웹 데스크탑 멀티태스킹 시 잦은 강제 정지 — `godot/scripts/game_root.gd:306-311`
- **[build-sec]** 웹 정적 사이트에 보안 헤더(CSP/HSTS/X-Frame-Options 등)가 전무 — `godot/tools/deploy_netlify_polished.sh:50-67`
- **[build-sec]** index.html에 인라인 <script>/<style> 사용 — 엄격 CSP 도입 시 충돌 — `godot/tools/build_web.sh:244-297`
- **[build-sec]** version/code가 1로 고정 + 완전 수동 증분 — 재제출 시 충돌/누락 위험 — `godot/export_presets.cfg:82`
- **[build-sec]** Godot 버전 핀이 워크플로/컨테이너/project.godot/문서 4곳에 분산·드리프트 — `.github/workflows/android.yml:28,36`
- **[build-sec]** PWA 매니페스트는 설치형/오프라인을 광고하나 서비스워커 미구현 — README '완전 오프라인'과 모순 — `godot/tools/build_web.sh:264`
- **[build-sec]** netlify.toml이 레포에 없고 dist/가 gitignore → netlify_build.sh의 Netlify 빌드 경로가 항상 실패(죽은 배포 경로) — `godot/tools/netlify_build.sh:16-30`
- **[build-sec]** CI 산출물에 GitHub Release 자동 첨부 없음 + 90일 후 만료 → 릴리스 추적성 상실 — `.github/workflows/android.yml:112-119`
- **[build-sec]** CI가 export_presets.cfg를 in-place sed 편집(APK용 format 토글) — 빌드 중 충돌/중단 시 잔존 위험 — `.github/workflows/android.yml:107-109`
- **[build-sec]** Web 프리셋 PWA orientation=Landscape — 게임은 portrait, 표준 PWA export 전환 시 잘못된 셸 — `godot/export_presets.cfg:35`
- **[build-sec]** 개인정보처리방침에 데이터 보유/삭제·관할법·고지 채널이 약함(스토어 심사 관점) — `store_assets/privacy.html:24-47`
- **[build-sec]** 디버그/푸시-env 로깅 스크립트들이 PII성 git/환경정보를 NDJSON 평문 로그로 남김 — `godot/tools/log_push_env_to_debug_log.sh:24-50`
