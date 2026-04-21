# HiteZero

> Survive waves of enemies. Take zero hits.

세로 화면(400×700) 아케이드 게임. 바닥의 파들(paddle)을 드래그해서 나이프 세례를 발사하고, 화면 위의 블록을 깨며 진행합니다. 별(STAR) 블록을 모두 부수면 스테이지 클리어, 빨간 적(RED_ENEMY)이 바닥에 닿거나 하트가 0이 되면 게임 오버입니다. 스프라이트 아틀라스의 한글 제목은 "유성막기"입니다.

Godot 4.4 + GDScript로 작성됐고, 데스크톱과 웹(no-threads) 양쪽으로 빌드됩니다. 그림 에셋 없이도 돌아가도록 모든 비주얼이 프로시저럴 드로잉으로 구현돼 있습니다.

## 프로젝트 구조

```
/                       Godot 프로젝트 루트
├── project.godot       엔진 설정 (4.4, GL Compatibility, 400×700 portrait)
├── export_presets.cfg  웹 export preset
├── icon.svg            앱 아이콘
├── scenes/             .tscn (boot / title / game / hud / player / knife / block)
├── scripts/            .gd (game_root, level_generator, 각 엔티티, session 등)
├── docs/               패리티 스펙, 웹 검증 로그, FX 롤아웃 노트
├── tools/              build_web.sh, QA 테스트 액션
├── progress.md         마이그레이션 로그
└── LICENSE
```

이전에는 같은 리포 안에 [phaser/](phaser/), [pj0zero/](pj0zero/), 그리고 루트 레벨 Godot까지 총 4개의 구현이 섞여 있었는데, Godot 포트만 남기고 전부 정리했습니다. 배경은 [progress.md](progress.md)와 [docs/phaser_parity_spec.md](docs/phaser_parity_spec.md)를 참고하세요.

## 게임플레이

- **조준 (AIMING)** — 드래그로 발사 각도 지정. 점선 가이드 표시, 각도는 바닥으로 못 쏘게 클램프.
- **발사 (SHOOTING)** — 놓으면 나이프가 66ms 간격으로 720 px/s로 발사됨. 이때부터 빨간 적이 낙하 시작.
- **튕겨내기** — 비행 중에도 파들을 좌우로 움직일 수 있고, 내려오는 나이프가 파들에 닿으면 타격 위치에 따라 반사각이 결정됨.

### 블록 타입

| 타입 | HP | 효과 |
|---|---|---|
| `NORMAL` | 현재 레벨 | 일반 벽돌 |
| `STAR` | 1 | 전부 부수면 스테이지 클리어 |
| `POW` | 1 | 파괴 시 60% 속도의 미니 나이프 8개로 폭발 |
| `RED_ENEMY` | 현재 레벨 | 발사 후 낙하 시작, 바닥 닿으면 하트 -1 |

### 종료 조건

- **스테이지 클리어** — 모든 `STAR` 블록 제거. 남은 나이프 수는 다음 스테이지로 이월.
- **게임 오버** — (A) 모든 나이프가 비활성 상태이고 스폰 대기열이 비었을 때, 또는 (B) 하트가 0이 됐을 때.

## 실행 방법

### 에디터로 실행

Godot 4.4+에서 [project.godot](project.godot)을 열고 **F5**를 누르면 `scenes/boot.tscn → title.tscn → game.tscn` 흐름으로 부팅됩니다.

### 웹 빌드

```bash
bash tools/build_web.sh
```

산출물:

- `build/godot-web/site_nothreads/` — 언팩된 웹 사이트 (godot.js + game.zip + index.html)
- `build/godot-web/hitezero-godot-web-site_nothreads.zip` — 그대로 업로드 가능한 묶음

로컬 서빙:

```bash
python3 -m http.server 8123 --directory build/godot-web/site_nothreads
# http://127.0.0.1:8123/index.html
```

빌드 스크립트는 `godot --headless --export-pack "Web" game.zip`으로 pack을 만들고, Godot의 `web_nothreads_release.zip` 템플릿에 그 pack과 커스텀 `index.html`을 얹어서 no-threads 사이트를 조립합니다. 템플릿 경로가 자동 탐지되지 않으면 `GODOT_TEMPLATE_DIR` 환경변수로 지정하세요.

## 아키텍처 주요 파일

- [scripts/game_root.gd](scripts/game_root.gd) — 메인 컨트롤러(약 746줄). 입력, 나이프 스폰, 수동 circle-vs-AABB 충돌, 반사, `AIMING`/`SHOOTING`/`STAGE_CLEAR`/`GAME_OVER` 상태 머신.
- [scripts/game_constants.gd](scripts/game_constants.gd) — 밸런스 상수, 블록 타입 enum, 팔레트.
- [scripts/level_generator.gd](scripts/level_generator.gd) — 스테이지별 프로시저럴 그리드 생성.
- [scripts/player.gd](scripts/player.gd), [scripts/knife.gd](scripts/knife.gd), [scripts/block.gd](scripts/block.gd) — 프로시저럴 렌더링 + 엔티티 개별 동작.
- [scripts/hud.gd](scripts/hud.gd) — 하트, 점수, 오버레이. 비인터랙티브 컨트롤은 `MOUSE_FILTER_IGNORE`로 게임플레이 입력을 먹지 않음.
- [scripts/session.gd](scripts/session.gd) — 오토로드. 세션 간 상태 보존.

주의할 물리 룰:

- 최소 Y 속도(약 18 px/s) 클램프로 얕은 수평 루프를 방지.
- 파들-나이프 충돌은 **하강 중인 나이프에만** 적용 → 상승 중인 나이프를 다시 잡는 사고 방지.

### JS 브릿지 (웹 빌드용)

[scripts/game_root.gd](scripts/game_root.gd)에서 브라우저 자동화/검증용으로 노출:

- `window.render_game_to_text()` — 현재 프레임의 텍스트 스냅샷
- `window.advanceTime(ms)` — 시뮬레이션 고정 시간 진행
- `window.__hitezero_state_json` — 블록/나이프/파들/모드 JSON 상태

## 알려진 이슈

- Godot 4.6의 `--export-release Web ...` 프리셋 구성 에러. 현재는 `--export-pack` 기반 경로가 안정적이며, 그 경로를 사용하는 `tools/build_web.sh`가 정식 빌드 수단입니다.
- 수동 QA 남은 항목: 드래그 조준 정확도, 발사 중 파들 드래그, 모바일 터치 느낌.

## 라이선스

[LICENSE](LICENSE) 참조.
