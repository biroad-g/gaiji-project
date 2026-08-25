#!/usr/bin/env python3
"""
post_build.py
flutter build web --release の後に実行する後処理スクリプト。

1. build/web/flutter_service_worker.js を読み込み、
   既存の RESOURCES ハッシュマップを抽出してそのまま使いつつ、
   キャッシュ戦略を Cache-first（全アセットプリキャッシュ）に書き換える。

2. build/web/manifest.json を web/manifest.json で上書きする。

Usage:
  cd /home/user/flutter_app
  python3 post_build.py
"""

import re
import shutil
import json
from pathlib import Path

BUILD_WEB = Path(__file__).parent / "build" / "web"
WEB_SRC   = Path(__file__).parent / "web"

# ──────────────────────────────────────────────
# 1. manifest.json を web/ のもので上書き
# ──────────────────────────────────────────────
src_manifest = WEB_SRC / "manifest.json"
dst_manifest = BUILD_WEB / "manifest.json"
shutil.copy2(src_manifest, dst_manifest)
print(f"✅ manifest.json を上書きしました: {dst_manifest}")

# ──────────────────────────────────────────────
# 2. Service Worker を Cache-first に書き換え
# ──────────────────────────────────────────────
sw_path = BUILD_WEB / "flutter_service_worker.js"
original_sw = sw_path.read_text(encoding="utf-8")

# Flutter が生成した RESOURCES オブジェクトをそのまま抽出する
resources_match = re.search(
    r"const RESOURCES\s*=\s*(\{[\s\S]*?\});",
    original_sw
)
if not resources_match:
    print("❌ RESOURCES オブジェクトが見つかりませんでした。SW の書き換えをスキップします。")
else:
    resources_block = resources_match.group(1)

    # バージョンは main.dart.js のハッシュから生成（毎ビルドで変わる）
    version_match = re.search(r'"main\.dart\.js":\s*"([a-f0-9]+)"', resources_block)
    cache_version = version_match.group(1)[:8] if version_match else "v1"

    new_sw = f"""'use strict';

// ============================================================
// 外字登録アプリ — オフライン対応 Service Worker
// キャッシュ戦略: Cache-first（インストール時に全アセット先読み）
// バージョン: {cache_version}
// ============================================================

const CACHE_NAME = 'gaiji-cache-{cache_version}';

// Flutter が生成したアセット一覧（ハッシュ付き）
const RESOURCES = {resources_block};

// ──────────────────────────────────────────────
// install: 全アセットをキャッシュに一括登録
// ──────────────────────────────────────────────
self.addEventListener('install', (event) => {{
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {{
      const urls = Object.keys(RESOURCES).map((key) => {{
        // ルート '/' は 'index.html' として扱う
        return key === '/' ? 'index.html' : key;
      }});
      // cache: 'reload' でネットワークから強制取得（CDNキャッシュをバイパス）
      return cache.addAll(
        urls.map((url) => new Request(url, {{ cache: 'reload' }}))
      );
    }}).catch((err) => {{
      console.warn('[SW] install: 一部アセットのキャッシュ失敗:', err);
    }})
  );
}});

// ──────────────────────────────────────────────
// activate: 古いキャッシュを削除
// ──────────────────────────────────────────────
self.addEventListener('activate', (event) => {{
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys
          .filter((key) => key !== CACHE_NAME)
          .map((key) => {{
            console.log('[SW] 古いキャッシュを削除:', key);
            return caches.delete(key);
          }})
      )
    ).then(() => self.clients.claim())
  );
}});

// ──────────────────────────────────────────────
// fetch: Cache-first 戦略
//   1. キャッシュにあれば即返す（オフライン対応・高速）
//   2. なければネットワーク取得してキャッシュに追加
// ──────────────────────────────────────────────
self.addEventListener('fetch', (event) => {{
  if (event.request.method !== 'GET') return;

  const url = new URL(event.request.url);

  // 同一オリジンのリクエストのみ処理
  if (url.origin !== self.location.origin) return;

  // クエリパラメータを除いたキーを生成
  let key = url.pathname.replace(/^\\//, '');
  if (!key || key === '') key = '/';

  event.respondWith(
    caches.open(CACHE_NAME).then((cache) =>
      cache.match(event.request).then((cached) => {{
        if (cached) {{
          // ✅ キャッシュヒット → 即返す
          return cached;
        }}
        // ❌ キャッシュミス → ネットワーク取得
        return fetch(event.request).then((response) => {{
          if (response && response.ok) {{
            cache.put(event.request, response.clone());
          }}
          return response;
        }}).catch(() => {{
          // ネットワークも失敗 → index.html をフォールバックとして返す
          if (event.request.headers.get('accept')?.includes('text/html')) {{
            return cache.match('index.html');
          }}
        }});
      }})
    )
  );
}});

// ──────────────────────────────────────────────
// message: skipWaiting / downloadOffline
// ──────────────────────────────────────────────
self.addEventListener('message', (event) => {{
  if (event.data === 'skipWaiting') {{
    self.skipWaiting();
  }}
}});
"""

    sw_path.write_text(new_sw, encoding="utf-8")
    print(f"✅ Service Worker を Cache-first に書き換えました (version: {cache_version})")
    print(f"   キャッシュ対象: {len(re.findall(chr(34), resources_block)) // 2} アセット")

print("\n🎉 post_build.py 完了！")
