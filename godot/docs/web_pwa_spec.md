# HiteZero — 웹 풀 PWA 적용 스펙 (P4/P8 잔여)

> 2026-06-15. 리서치(Godot 4.6 공식문서·web.dev·Apple·Google Play 배지) 기반. **이미 반영분**:
> manifest.webmanifest · apple/mobile web-app 메타 · netlify manifest MIME · 터치 CSS.
> **아래는 잔여** — 완전 설치형(안드로이드 install prompt)·오프라인·iOS 오디오·구브라우저 대응.
> 모두 웹 전용(게임 바이너리·AAB 무관). 라이브 배포 후 실기 검증 필요(헤드리스 검증 불가 영역).

## A. 미니멀 서비스워커 (완전 설치형 + 오프라인)
현 `build_web.sh` 셸은 `serviceWorker:''`이고 Godot SW는 inert 템플릿. 정적 사이트라 **손수 미니멀 SW**가 가장 단순. `deploy_netlify_polished.sh`가 publish에 `sw.js`를 쓰게 추가:
```js
// sw.js — cache-first, 버전 올리면 자동 갱신
const CACHE = 'hitezero-v1';   // ← 배포마다 버전 +1
const CORE = ['./','./index.html','./godot.js','./godot.wasm',
  './godot.audio.worklet.js','./godot.audio.position.worklet.js',
  './favicon-192.png','./favicon-512.png','./manifest.webmanifest'];
self.addEventListener('install', e => { self.skipWaiting();
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(CORE).catch(()=>{}))); });
self.addEventListener('activate', e => { e.waitUntil(
  caches.keys().then(ks => Promise.all(ks.filter(k=>k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim())); });
self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  e.respondWith(caches.match(e.request).then(r => r || fetch(e.request).then(resp => {
    const cp = resp.clone(); caches.open(CACHE).then(c => c.put(e.request, cp)); return resp;
  }).catch(()=>caches.match('./index.html')))); });
```
- 등록: `build_web.sh` 셸 `<script>`의 `new Engine({... serviceWorker:''})` → `serviceWorker: 'sw.js'` (Godot 로더가 등록) **또는** 셸 끝에 `if('serviceWorker' in navigator) navigator.serviceWorker.register('sw.js');`
- `deploy_netlify_polished.sh`: `sw.js`를 `store_assets/web/`에 두고 publish로 cp. netlify.toml에 SW no-cache 헤더 추가:
```toml
[[headers]]
  for = "/sw.js"
  [headers.values]
    Cache-Control = "public, max-age=0, no-cache, must-revalidate"
```
- ⚠️ **SW 갱신 함정**: 배포마다 `CACHE` 버전 올리지 않으면 유저가 구버전에 갇힘. no-cache 헤더 필수.
- ⚠️ COOP/COEP **추가 금지**(nothreads라 불필요 + `COEP:require-corp`가 크로스오리진 Play 배지 차단).

## B. iOS 오디오 — 탭-투-플레이 게이트
iOS Safari는 user gesture 전 AudioContext suspend → 첫 사운드 무음. 게이트로 해결(프리미엄 "press to play"도 됨). `build_web.sh` 셸:
```js
// engine.startGame() 호출을 탭 뒤로 이동
const gate = document.getElementById('gate');   // <div id="gate">▶ TAP TO PLAY</div> (로더 위)
let started = false;
function start(){ if(started) return; started=true; gate.style.display='none';
  engine.startGame({ onProgress: onLoadProgress }).then(/* 기존 then */); }
gate.addEventListener('pointerdown', start, {once:true});
```
(현재는 자동 startGame — 데스크탑/안드로이드는 OK, iOS만 첫 사운드 이슈.)

## C. 구브라우저 가드
`godot.js`는 Safari<15.2 / FF<100 / Chrome<95에서 **로드시 throw** → 빈 화면. 셸 `<script>` 앞부분:
```js
if (typeof Engine === 'undefined' || !(Engine.isWebGLAvailable && Engine.isWebGLAvailable())) {
  document.getElementById('unsupported').style.display = 'flex';  // "Browser not supported, update" 안내
} else { /* new Engine(...) ... */ }
```

## D. (선택) 커스텀셸 이관 — 재export 안전
현재 `build_web.sh`가 heredoc로 셸 생성(파이프라인 자체 관리)이라 재export 클로버 문제는 없음. 표준 Godot PWA export로 가려면 `export_presets.cfg`:
```ini
progressive_web_app/enabled=true
progressive_web_app/orientation=2        # ⚠️ 현재 1=Landscape 오설정 → 2=Portrait
progressive_web_app/display=0            # fullscreen
progressive_web_app/ensure_cross_origin_isolation_headers=false
html/custom_html_shell="res://web/shell.html"   # $GODOT_CONFIG 사용 셸
```
단 이는 build_web.sh 파이프라인 대체라 큰 변경 — 현 heredoc + 위 A~C 추가가 더 저위험.

## 적용 후 검증
- Chrome DevTools → Application → Manifest(installable·에러0) + Service Workers(activated).
- Lighthouse PWA. 안드로이드 Chrome A2HS + iOS Safari "홈 화면에 추가". 실기 iPhone 탭 후 사운드. 구UA 스푸핑으로 가드.

## 출처
Godot web export/custom-shell docs(4.6) · web.dev Web App Manifest · MDN manifest orientation · Apple supported meta tags · Google Play 배지 가이드(partnermarketinghub).
