'use strict';
// 外字登録 -- オフライン優先 Service Worker (version: 3253704a7e96)
const CACHE_NAME = 'gaiji-cache-3253704a7e96';
const URLS = ["canvaskit/chromium/canvaskit.js", "canvaskit/chromium/canvaskit.js.symbols", "canvaskit/chromium/canvaskit.wasm", "canvaskit/canvaskit.js", "canvaskit/canvaskit.js.symbols", "canvaskit/canvaskit.wasm", "flutter.js", "flutter_bootstrap.js", "index.html", "main.dart.js", "version.json", "assets/packages/cupertino_icons/assets/CupertinoIcons.ttf", "assets/fonts/MaterialIcons-Regular.otf", "assets/shaders/ink_sparkle.frag", "assets/AssetManifest.json", "assets/AssetManifest.bin", "assets/AssetManifest.bin.json", "assets/FontManifest.json", "assets/assets/fonts/NotoSansJP-Regular.otf", "icons/Icon-192.png", "icons/Icon-512.png", "icons/Icon-maskable-192.png", "icons/Icon-maskable-512.png", "favicon.png", "manifest.json"];

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE_NAME);
    // メモリ負担を避けるため、同時に3ファイルずつ順番に保存する(iPhone対策)。
    // 失敗したものは、通常アクセス時に補完される。
    const queue = URLS.slice();
    const worker = async () => {
      while (queue.length) {
        const url = queue.shift();
        try {
          const res = await fetch(new Request(url, { cache: 'reload' }));
          if (res && res.ok) await cache.put(url, res);
        } catch (e) {
          // オフライン中の更新などは無視
        }
      }
    };
    await Promise.all([worker(), worker(), worker()]);
    const idx = await cache.match('index.html');
    if (idx) await cache.put('./', idx.clone());
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)));
  })());
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;

  event.respondWith((async () => {
    const cache = await caches.open(CACHE_NAME);

    // 画面の表示そのもの(ページ遷移)は index.html を即返す
    if (req.mode === 'navigate') {
      const page = await cache.match('index.html');
      if (page) return page;
    }

    // それ以外: キャッシュ優先 (?v=xxx などのクエリは無視して照合)
    const hit = await cache.match(req, { ignoreSearch: true });
    if (hit) return hit;

    try {
      const res = await fetch(req);
      if (res && res.ok) cache.put(req, res.clone());
      return res;
    } catch (e) {
      if (req.mode === 'navigate') {
        const page = await cache.match('index.html');
        if (page) return page;
      }
      return new Response('オフラインです', {
        status: 503,
        headers: { 'Content-Type': 'text/plain; charset=utf-8' },
      });
    }
  })());
});

self.addEventListener('message', (event) => {
  if (event.data === 'skipWaiting') self.skipWaiting();
});
