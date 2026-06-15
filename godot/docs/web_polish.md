# HiteZero — 웹 빌드 마무리 폴리싱 (Netlify)

> 2026-06-14. 라이브: https://hitezero.netlify.app (Godot 웹 export, nothreads).
> 목적: 엔진 셸은 안 건드리고(로더 보존) **파비콘 · 공유 카드(OG) · 메타**만 얹어
> 브라우저 탭·링크 공유·검색 노출을 다듬는다. 게임 로직/코드 변경 없음.

## 생성된 자산 (`store_assets/web/`)
- `favicon-16/32/48/180/192/512.png` — 파비콘 + apple-touch(180) + PWA(192/512)
- `og_image_1200x630.png` — 링크 공유 카드(트위터/디스코드/카톡 미리보기)

## 적용 순서 (다음 웹 배포 시)
1. 위 파일들을 **웹 publish 루트로 복사**(godot.wasm·index.html과 같은 폴더):
   `cp store_assets/web/favicon-*.png store_assets/web/og_image_1200x630.png <publish>/`
2. 내보낸 `index.html`의 `<head>` 안(엔진 `<script>` 위, 아무 곳)에 아래 **스니펫 삽입**.
   Godot가 재export하면 index.html이 덮어쓰이므로, 커스텀 HTML 셸
   (Export → Web → HTML/Custom HTML Shell)에 넣거나 export 후 후처리로 주입.
3. 재배포(Netlify Drop 또는 커넥터). `/privacy`는 유지.

## `<head>` 삽입 스니펫
```html
<!-- HiteZero web polish: favicon + share card -->
<link rel="icon" type="image/png" sizes="32x32" href="favicon-32.png">
<link rel="icon" type="image/png" sizes="16x16" href="favicon-16.png">
<link rel="apple-touch-icon" sizes="180x180" href="favicon-180.png">
<meta name="description" content="HiteZero — aim, ricochet knives, and smash neon blocks. One-handed neon arcade. Plays free in your browser.">
<meta name="theme-color" content="#050510">
<!-- Open Graph -->
<meta property="og:type" content="website">
<meta property="og:title" content="HiteZero — Neon Knife Arcade">
<meta property="og:description" content="Aim, ricochet knives, smash neon blocks. One-handed arcade — play free in browser.">
<meta property="og:url" content="https://hitezero.netlify.app/">
<meta property="og:image" content="https://hitezero.netlify.app/og_image_1200x630.png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<!-- Twitter -->
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="HiteZero — Neon Knife Arcade">
<meta name="twitter:description" content="Aim, ricochet knives, smash neon blocks. One-handed arcade — play free in browser.">
<meta name="twitter:image" content="https://hitezero.netlify.app/og_image_1200x630.png">
```

## (선택) PWA manifest — 홈화면 설치용
`manifest.webmanifest`를 publish 루트에 두고 `<link rel="manifest" href="manifest.webmanifest">` 추가:
```json
{ "name": "HiteZero", "short_name": "HiteZero", "start_url": "./index.html",
  "display": "fullscreen", "orientation": "portrait", "background_color": "#050510",
  "theme_color": "#050510",
  "icons": [ {"src":"favicon-192.png","sizes":"192x192","type":"image/png"},
             {"src":"favicon-512.png","sizes":"512x512","type":"image/png"} ] }
```

## 주의
- 엔진 부트스트랩 `<script>`/`<canvas>`는 **건드리지 말 것**(로더 깨짐). 위는 전부 `<head>` 추가분.
- `og:image`는 **절대 URL** 필요 — 배포 도메인 기준(hitezero.netlify.app).
- 검증: 배포 후 https://hitezero.netlify.app 로 og 미리보기(메타 디버거)·탭 파비콘 확인.
