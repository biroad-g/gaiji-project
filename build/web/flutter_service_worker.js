'use strict';

// ============================================================
// 外字登録アプリ — オフライン対応 Service Worker
// キャッシュ戦略: Cache-first（インストール時に全アセット先読み）
// バージョン: 9820abd2
// ============================================================

const CACHE_NAME = 'gaiji-cache-9820abd2';

// Flutter が生成したアセット一覧（ハッシュ付き）
const RESOURCES = {"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"flutter_bootstrap.js": "082299c3b3bd8a2744e0180028e79a81",
"index.html": "3a365534730b59e3f10eb3817ad20aa7",
"/": "3a365534730b59e3f10eb3817ad20aa7",
"main.dart.js": "9820abd2198063dd06060fd05d4cec36",
"version.json": "24c46157e6349fa98d884da9f17bd31a",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/fonts/MaterialIcons-Regular.otf": "b5a19c2411e5714e98dd1db0b1d00aec",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.json": "2efbb41d7877d10aac9d091f58ccd7b9",
"assets/AssetManifest.bin": "693635b5258fe5f1cda720cf224f158c",
"assets/AssetManifest.bin.json": "69a99f98c8b1fb8111c5fb961769fcd8",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/NOTICES": "fcf1495893910f429df5fac7c5720ade",
"icons/Icon-192.png": "ece04389b197909180dab697886a7c70",
"icons/Icon-512.png": "ef17a7587c5ef98404e87656a85012d2",
"icons/Icon-maskable-192.png": "ece04389b197909180dab697886a7c70",
"icons/Icon-maskable-512.png": "ef17a7587c5ef98404e87656a85012d2",
"favicon.png": "21e2b905e1631c4b1b4ef256fd1cc27f",
"manifest.json": "d48ab9f5c9cfa1e5fd4858d041e0fbdc"};

// ──────────────────────────────────────────────
// install: 全アセットをキャッシュに一括登録
// ──────────────────────────────────────────────
self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      const urls = Object.keys(RESOURCES).map((key) => {
        // ルート '/' は 'index.html' として扱う
        return key === '/' ? 'index.html' : key;
      });
      // cache: 'reload' でネットワークから強制取得（CDNキャッシュをバイパス）
      return cache.addAll(
        urls.map((url) => new Request(url, { cache: 'reload' }))
      );
    }).catch((err) => {
      console.warn('[SW] install: 一部アセットのキャッシュ失敗:', err);
    })
  );
});

// ──────────────────────────────────────────────
// activate: 古いキャッシュを削除
// ──────────────────────────────────────────────
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys
          .filter((key) => key !== CACHE_NAME)
          .map((key) => {
            console.log('[SW] 古いキャッシュを削除:', key);
            return caches.delete(key);
          })
      )
    ).then(() => self.clients.claim())
  );
});

// ──────────────────────────────────────────────
// fetch: Cache-first 戦略
//   1. キャッシュにあれば即返す（オフライン対応・高速）
//   2. なければネットワーク取得してキャッシュに追加
// ──────────────────────────────────────────────
self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;

  const url = new URL(event.request.url);

  // 同一オリジンのリクエストのみ処理
  if (url.origin !== self.location.origin) return;

  // クエリパラメータを除いたキーを生成
  let key = url.pathname.replace(/^\//, '');
  if (!key || key === '') key = '/';

  event.respondWith(
    caches.open(CACHE_NAME).then((cache) =>
      cache.match(event.request).then((cached) => {
        if (cached) {
          // ✅ キャッシュヒット → 即返す
          return cached;
        }
        // ❌ キャッシュミス → ネットワーク取得
        return fetch(event.request).then((response) => {
          if (response && response.ok) {
            cache.put(event.request, response.clone());
          }
          return response;
        }).catch(() => {
          // ネットワークも失敗 → index.html をフォールバックとして返す
          if (event.request.headers.get('accept')?.includes('text/html')) {
            return cache.match('index.html');
          }
        });
      })
    )
  );
});

// ──────────────────────────────────────────────
// message: skipWaiting / downloadOffline
// ──────────────────────────────────────────────
self.addEventListener('message', (event) => {
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
  }
});
