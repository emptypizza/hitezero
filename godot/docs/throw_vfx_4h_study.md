# HiteZero Throw / Output VFX 4h Study Log

Started: 2026-04-28 03:29 KST
Scope: HiteZero Godot throw/knife-output feel, player sprite output VFX, title/presentation polish, and reference-informed improvement notes.

Constraints:
- Do not commit or push.
- Do not change external/public tunnel URLs.
- Prefer study notes, QA observations, and small safe verification over disruptive runtime/server changes.
- If code changes are suggested, separate them from already-applied changes.

## Baseline already accomplished before study

- Player sprite uses maid idle/attack/combat/gameover frames.
- `Player.play_output(aim_angle)` is wired from `GameRoot._spawn_knife()`.
- Output VFX includes slash/trail, flash, particles, recoil, and light shake.
- Title screen has glass panel, label shadows/outlines, neon buttons, hidden tray clutter for preview, and safer Best Score spacing.
- Latest verified web pack before this study: `game-dad7af8c56471bc2.zip`.
- Verified tests/build/browser QA passed before study began.

## Rolling notes

## Check-in 1 — throw timing and muzzle alignment

Time: 2026-04-28 03:58 KST

### Observations

- Existing log only had the baseline section, so this pass focused on the first concrete angle: player throw/output timing, muzzle origin, and quick runtime readability.
- Source inspection confirms `GameRoot._spawn_knife()` spawns each knife at `(fire_x, paddle_y - GameConstants.PADDLE_Y_OFFSET)` and immediately calls `player.play_output(aim_angle)`. `Player._get_muzzle_origin()` mirrors that local origin with `Vector2(0, -PADDLE_Y_OFFSET) + dir * 2.0`, so the flash/trail is intentionally aligned to the actual projectile spawn point rather than the maid body center.
- Timing math: `SPAWN_INTERVAL` is 0.066s (~4 frames at 60fps, ~2 frames at 30fps). `OUTPUT_DURATION` is 0.52s (~31 frames at 60fps) and flash is 0.26s (~16 frames at 60fps), so VFX from consecutive knives overlap strongly. Attack frames split into five ~0.104s windows, which is readable for a single throw but may feel like a held attack pose during the 3-knife burst.
- Asset sizing check: attack frames vary widely in source width/height (137-247px wide, 229-249px tall) but are rescaled by target height. This keeps height stable, while silhouette/arm reach still changes enough to sell the output motion.
- Browser QA on the existing local server at `127.0.0.1:8123` successfully entered gameplay and fired a vertical throw. Game state showed three active knives and score/block updates. Visually, the player and knives were readable, but the instantaneous output flash/trail was easier to miss against the detailed neon background than the source values imply.
- Verification run: `python3 tools/test_player_output_vfx.py && python3 tools/test_red_enemy_sprite.py` passed; `godot --headless --path /Users/choimarc/hitezero/godot --quit` launched and quit cleanly.

### Concrete recommendations

- Keep the current muzzle-origin alignment; it is technically coherent with the projectile spawn and should not be moved unless the actual hand/tray art is re-anchored.
- For stronger perceived "쓰로" snap, consider compressing only the brightest flash to the first 0.10-0.14s while keeping the longer trail/particles for readability. This would make each 0.066s knife pulse feel more like separate shots instead of one continuous glow.
- Add a very short high-contrast projectile birth cue at the muzzle (for example a 1-2 frame white/yellow star or ring) because browser QA suggests the current flash can blend into the neon/background sparkle field.
- If broadening the effect later, prefer adding a thin dark/blue outline or core-then-glow structure to the knife trail rather than only increasing alpha; this improves mobile readability without washing out the maid sprite.

### Risk / priority

- Priority: Medium-high for feel/readability, because the throw is the player's primary action and first gameplay feedback.
- Risk: Low for documentation and QA notes. Actual VFX tuning should be treated as medium risk because rapid 0.066s overlapping throws can easily become noisy on mobile if all flash/trail values are increased together.

### Files changed

- Changed only this study log: appended `Check-in 1 — throw timing and muzzle alignment`.
- No gameplay/code/assets/build output were changed during this check-in.

## Check-in 2 — projectile trail readability and layer separation

Time: 2026-04-28 04:28 KST

### Observations

- Existing coverage already handled throw timing and muzzle alignment, so this pass focused on what happens after the knife leaves the player: projectile visibility, trail/readability, and draw-order separation against the neon playfield.
- Source inspection shows the player-side output VFX is drawn on `Player/OutputVfx` with `z_index = 8`, above body/tray and effectively above the default-z knives/blocks. This is good for a launch flash because it avoids the slash being hidden by the player sprite or projectile layer.
- The active `Knife` itself is intentionally simple: a `16x24` texture, scaled `1.0` for normal knives and `0.68` for mini-knives, rotated to velocity. There is no per-projectile afterimage/trail node; most motion readability comes from the launch slash plus the bright knife sprite and impact bursts.
- Timing/distance check at current constants: knife speed is `720 px/s`; knives move about `47.5 px` between 0.066s burst spawns, `187 px` during the 0.26s flash window, and `374 px` during the 0.52s output window. This means the muzzle flash remains near the player while the projectile is already far into the field; the launch cue and projectile body read as two separate events.
- Browser QA on `127.0.0.1:8123` entered gameplay, fired a vertical shot via synthetic mouse input, and showed three active knives in the web bridge state. The white projectile was readable, but the thin blue/pink/yellow trail accents and small launch sparkle still blended with the bright blue background/grid. Static screenshot could not reliably confirm camera shake, which is expected for a very light 0.05s shake.
- Verification run passed: `python3 tools/test_player_output_vfx.py && python3 tools/test_red_enemy_sprite.py && godot --headless --path /Users/choimarc/hitezero/godot --quit`. Browser console showed no JS errors after QA.

### Concrete recommendations

- Keep the high `OutputVfx` draw order; the layer choice is correct for making the launch slash sit in front of both the maid sprite and default projectile layer.
- If improving projectile readability, add a restrained per-knife trail/afterimage rather than extending the player slash much farther. A short 2-3 sample ghost trail behind each active knife would follow the projectile into the playfield and reduce the current gap between muzzle flash and moving blade.
- Give any future trail a dark/cyan outline or two-tone structure: a slim dark outer stroke plus white/yellow core will read better over the blue neon background than simply raising alpha on the current pastel trail lines.
- Keep camera shake conservative for mobile comfort, but consider a slightly more deterministic micro-nudge on launch (for example one-frame vertical recoil or brief `world.position` bias opposite the shot) if testers still miss the throw impact. Random 0.05s shake is hard to perceive or evaluate in screenshots.

### Risk / priority

- Priority: Medium. The projectile itself is readable, but the attack-output trail is still less legible than the block/HUD presentation and could make the primary action feel softer than intended.
- Risk: Low for documentation and tests. Adding per-knife trails later is medium risk because every extra draw per active/mini knife can add visual clutter during POW bursts; cap trail length and alpha aggressively.

### Files changed

- Changed only this study log: appended `Check-in 2 — projectile trail readability and layer separation`.
- No gameplay/code/assets/build output were changed during this check-in.

## Check-in 3 — 릴리즈-출력 반응, 리코일, 셰이크

Time: 2026-04-28 04:57 KST

### Observations

- Check-in 1-2에서 머즐 정렬과 투사체/트레일 분리를 이미 다뤘으므로, 이번 구간은 입력 릴리즈 직후의 반응성, 몸 리코일, 카메라 셰이크, 즉시 피드백을 집중 확인했다.
- 소스상 `_start_shooting()`은 플레이어 스케일 팝 트윈을 즉시 시작하지만, `_spawn_knife()`를 바로 호출하지는 않는다. `spawn_timer`만 시작하므로 첫 실제 칼/출력 이벤트는 첫 `SPAWN_INTERVAL` 타임아웃 때 발생한다. 브라우저 QA에서도 마우스 업 직후 상태가 `SHOOTING`, `knives_to_spawn = 3`, `knives = []`로 확인됐다.
- 타이밍 계산상 `SPAWN_INTERVAL = 0.066s`는 60fps 기준 약 4프레임, 30fps 기준 약 2프레임이다. 짧은 값이지만 실제 `player.play_output()`, 머즐 버스트, 칼 오브젝트, 셰이크는 릴리즈보다 살짝 늦게 시작된다. 스케일 트윈이 그 공백을 메우지만, 사용자가 즉시 발사를 기대하면 첫 "쓰로" 신호가 약간 부드럽게 느껴질 수 있다.
- `_spawn_knife()`는 중요한 발사 피드백을 한 번에 묶고 있다: `player.play_output(aim_angle)`, `shake_time_remaining = maxf(..., 0.05)`, 스폰 지점의 작은 `_burst_feedback()`. 3개의 칼은 0.066초 간격으로 나오고 셰이크는 `maxf`로 0.05초까지만 갱신되므로, 큰 흔들림으로 누적되지 않고 가볍게 유지된다.
- 셰이크는 의도적으로 매우 미세하다. `world.position`을 ±2px 범위에서 0.05초 동안 랜덤 이동시키며, 이는 60fps 기준 약 3프레임, 30fps 기준 약 1.5프레임이다. 정지 스크린샷 QA에서 잘 보이지 않은 것도 이 수치와 맞다. 현재 셰이크는 시각적 강조라기보다 촉각적인 미세 노이즈에 가깝다.
- 리코일은 몸체에만 적용되고 2차 감쇠된다. `_output_recoil_offset()`은 발사 반대 방향으로 6px에서 시작해 0.066초 후 약 4.57px, 0.132초 후 약 3.34px, 0.26초 후 약 1.5px까지 줄어든다. 수직 발사에서는 메이드 몸만 아래로 살짝 내려가고 트레이/투사체 원점은 고정되어 머즐 정렬은 안전하지만, 손/트레이에서 오는 물리적 킥은 덜 강하게 보일 수 있다.
- 브라우저 QA는 `127.0.0.1:8123`에서 게임 진입 후 수직 발사를 수행했다. 약 220ms 뒤 active knife 1개, 점수/블록 갱신, 콘솔/JS 오류 없음이 확인됐다. 시각 검토도 소스 분석과 일치했다: 투사체 자체는 읽히지만, 발사 리코일/셰이크/히트 피드백은 정지 캡처에서 판단하기엔 너무 짧다.
- 검증 실행 통과: `python3 tools/test_player_output_vfx.py && python3 tools/test_red_enemy_sprite.py && godot --headless --path /Users/choimarc/hitezero/godot --quit`.

### Concrete recommendations

- 입력감 강화를 원하면 마우스/터치 릴리즈 순간 첫 칼을 즉시 스폰하고, 타이머는 남은 버스트 칼에만 쓰는 방안을 검토할 만하다. 이렇게 하면 0.066초 릴리즈-출력 공백이 사라진다. 다만 버스트 간격, 초반 충돌, 점수 발생 타이밍이 달라질 수 있어 실제 적용은 중간 위험이다.
- 게임플레이 타이밍을 유지해야 한다면, 첫 타이머 칼 이전에 1-2프레임짜리 즉시 "커밋" 신호를 추가하는 편이 안전하다. 예: 머즐 글린트, 트레이 틱, 몸/트레이 예비 팝. 스폰 순서를 바꾸지 않고도 지연이 의도된 연출처럼 느껴진다.
- 카메라 셰이크는 모바일 피로도를 고려해 현재처럼 보수적으로 유지하되, 완전 랜덤 ±2px보다 발사 반대 방향으로 1프레임 치우친 결정적 넛지를 먼저 주는 편이 읽기 쉽다. 이후 현재 랜덤 셰이크를 붙이면 힘 방향과 미세 진동을 같이 줄 수 있다.
- 실제 투사체 스폰 원점은 유지하되, 트레이나 작은 머즐 링만 아주 짧은 오버슈트/리코일을 공유하게 하는 것도 좋다. 현재 몸체-only 리코일은 정렬 안정성은 높지만, 플레이어가 공격 힘을 기대하는 손/트레이 영역의 반응은 약하다.
- 향후 브라우저 QA 자동화를 위해 `output_elapsed`, `shake_time_remaining`, `world.position` 같은 값을 디버그 전용 브리지에 노출하면 좋다. 단, 이는 테스트 편의용으로만 두고 프로덕션 게임플레이 변경으로 확장하지 않는 것이 안전하다.

### Risk / priority

- Priority: Medium-high. 첫 출력 지연 0.066초는 작지만, 쓰로가 핵심 조작이라 릴리즈 후 첫 몇 프레임의 반응성이 전체 손맛을 크게 좌우한다.
- Risk: 문서/QA 기록은 Low. 즉시 비투사체 큐 추가는 Low, 첫 칼 즉시 스폰으로 타이밍을 바꾸는 작업은 충돌/점수/VFX 겹침에 영향을 줄 수 있어 Medium.
- 셰이크 튜닝 위험도: Low-medium. 세기/시간을 단순히 키우면 모바일에서 피로하거나 지저분해질 수 있으므로, 방향성 있는 짧은 움직임이 더 안전하다.

### Files changed

- Changed only this study log: appended `Check-in 3 — 릴리즈-출력 반응, 리코일, 셰이크`.
- No gameplay/code/assets/build output were changed during this check-in.

