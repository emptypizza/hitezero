# itch.io Release Notes

Use the Godot web build output, not the source repository ZIP.

## Upload file

- Upload: `dist/hitezero-itch-html.zip` (copy of `dist/godot-web/hitezero-godot-web-site_nothreads.zip` after `bash godot/tools/build_web.sh dist/godot-web`)
- This ZIP already contains `index.html` at the root.

## Recommended project metadata

- Title: `HiteZero`
- Alternate title: `HiteZero - Meteor Knife Guard`
- Korean title option: `하이트제로`
- Project URL: `hitezero`
- Short description: `Bounce knives to destroy STAR blocks before red enemies reach the floor.`
- Korean short description: `칼을 튕겨 STAR 블록을 모두 부수고 RED_ENEMY가 바닥에 닿기 전에 막아내는 아케이드 액션 게임`
- Classification: `Games`
- Kind of project: `HTML`
- Release status: `Released`
- Pricing: `No payments`

If the existing itch.io project URL must stay as `randgirls00`, keep the URL and only update the title/description.

## Page body suggestion

```md
## HiteZero

An arcade action prototype built in Godot 4.

Bounce knives off the tray, clear every STAR block, and survive the falling RED_ENEMY blocks.

### Controls
- Mouse / Touch: drag to aim, release to fire
- Mouse / Touch during shooting: drag horizontally to move
- Keyboard: A / D or Left / Right to move

### Goal
- Destroy every STAR block to clear the stage
- Destroyed STAR blocks add bonus knives for the next stage
- Avoid letting RED_ENEMY blocks reach the danger zone
```

## Recommended screenshots

- Capture and store under a folder you prefer (e.g. `docs/itchio/` or `dist/itchio/`), then attach on itch.io:
  - `title-page.png`
  - `gameplay-page.png`

## Post-upload itch settings

- Enable `This file will be played in the browser`
- Enable fullscreen button if shown
- If embed size is requested, start with:
  - Width: `400`
  - Height: `700`
- If the default embed looks cramped on the page, increase to:
  - Width: `800`
  - Height: `1400`

## Notes

- `hitezero-main.zip` is not the correct upload artifact for itch.io HTML play.
- Current web export path is pack-based and works through the assembled no-threads site.
