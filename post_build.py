#!/usr/bin/env python3
"""
post_build.py  --  flutter build web の後に実行する後処理

  flutter build web --release --no-web-resources-cdn
  python3 post_build.py

やること
  1. manifest.json を web/ のもので上書き
  2. flutter_service_worker.js を「オフライン優先」の自作版に置き換え
     - 全ファイルを1つずつ個別にキャッシュ（1つ失敗しても全体は止まらない）
     - キャッシュ名は全ファイルのハッシュから作る（何か変われば自動で更新）
     - 画面遷移リクエストは常に index.html をキャッシュから返す
     - 使わない skwasm 系ファイルはキャッシュしない（容量節約）
"""
import hashlib
import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).parent
BUILD_WEB = ROOT / "build" / "web"
WEB_SRC = ROOT / "web"

# 1. manifest
shutil.copy2(WEB_SRC / "manifest.json", BUILD_WEB / "manifest.json")
print("manifest.json を上書きしました")

# DISABLE_AUTO_SW: Flutter標準のSW自動登録を止める(登録は index.html 側で表示後に行う)
bs = BUILD_WEB / "flutter_bootstrap.js"
b = bs.read_text(encoding="utf-8")
b2 = re.sub(r"_flutter\.loader\.load\(\{\s*serviceWorkerSettings:\s*\{[^}]*\}\s*\}\);", "_flutter.loader.load({});", b)
if b2 == b:
    print("警告: flutter_bootstrap.js の書き換え箇所が見つかりません")
bs.write_text(b2, encoding="utf-8")
print("flutter_bootstrap.js: SW自動登録を無効化しました")

# 2. Flutter が出力した RESOURCES を取得
sw_path = BUILD_WEB / "flutter_service_worker.js"
original = sw_path.read_text(encoding="utf-8")
m = re.search(r"const RESOURCES\s*=\s*(\{[\s\S]*?\});", original)
if not m:
    raise SystemExit("RESOURCES が見つかりません。ビルドをやり直してください。")
resources = json.loads(m.group(1))

# 実在するファイルだけ・不要ファイルを除外
SKIP = ("canvaskit/skwasm", "assets/NOTICES")
urls = []
for key in resources:
    if key == "/":
        continue
    if any(key.startswith(s) for s in SKIP):
        continue
    if not (BUILD_WEB / key).exists():
        continue
    urls.append(key)

# index.html 等は SW 自身が書き換えた後のハッシュで版を決める
# 版は「全ファイルの内容ハッシュ」から作る
h = hashlib.sha256()
for u in sorted(urls):
    h.update(u.encode())
    h.update((BUILD_WEB / u).read_bytes())
version = h.hexdigest()[:12]

total = sum((BUILD_WEB / u).stat().st_size for u in urls)

sw = """'use strict';
// 外字登録 -- オフライン優先 Service Worker (version: __VERSION__)
const CACHE_NAME = 'gaiji-cache-__VERSION__';
const URLS = __URLS__;

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
"""
sw = sw.replace("__VERSION__", version).replace("__URLS__", json.dumps(urls, ensure_ascii=False))
sw_path.write_text(sw, encoding="utf-8")

print(f"Service Worker を書き換えました  version={version}")
print(f"  キャッシュ対象 {len(urls)} ファイル / 合計 {total/1024/1024:.1f} MB")
