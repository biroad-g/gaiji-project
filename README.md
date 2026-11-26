# 古字アルバム（gaiji_album）

寺院で使われる外字（異体字・古字・梵字など、JIS漢字に無い字）を、
**撮影 → 一字を切り取り → 名前とメモを付けて保存** する、オフライン完結の外字アルバムです。

- 端末内保存（Hive。Web では IndexedDB）— **ネット接続不要・完全オフライン動作**
- 切り取った字形は **背景を透過した PNG** で保存でき、Word・お便り・法話資料にそのまま貼れます

---

## 使い方

1. **アルバム**タブ右下の「外字を撮影」、または **撮影**タブへ
2. 「カメラで撮影する」／「端末の写真から読み込む」を選択
3. **切り取りツール**で漢字一字を枠で囲む
   - 枠はドラッグで移動、四隅の丸いつまみで大きさ調整
   - 「背景を透過」… 紙の地色を消して墨だけ残す（市松模様で確認できます）
   - 「余白を自動調整」… 墨の外接矩形に合わせて余白を詰め、ほぼ正方形に整える
   - 「墨の濃さ」… 透過のしきい値（既定150）。薄い墨のときは上げてください
4. **登録画面**で入力
   - 名称（必須）／読み／分類（異体字・古字・梵字・印影・その他）／出典／メモ
5. アルバムに一覧表示。カードをタップで詳細（**PNG保存・共有・編集・削除**）

### 一覧の操作
- 検索アイコン … 名称・読み・出典・メモから横断検索
- 下部のチップ … 分類で絞り込み（件数表示つき）／並び替え（新しい順・古い順・名称順・読み順）

---

## 主な機能

| 機能 | 実装 |
|---|---|
| 撮影・画像読み込み | `image_picker`（Android カメラ／ギャラリー、Web はファイル選択） |
| 一字の切り取り | `lib/screens/crop_editor.dart`（純 Dart のカスタムジェスチャ） |
| 背景透過・余白調整 | `lib/services/crop_service.dart`（`image` パッケージ、純 Dart） |
| 端末内保存 | `hive` + `hive_flutter`（`GaijiRepository`） |
| 状態管理 | `provider`（`GaijiProvider`） |
| PNG 書き出し・共有 | `path_provider` + `share_plus` |
| 日本語フォント同梱 | Noto Sans JP / Noto Serif JP（サブセット版を `assets/fonts`） |

> 切り取り・透過処理はすべて端末内の純 Dart で完結するため、
> サーバーもネット接続も不要です（オフラインでそのまま使えます）。

---

## 開発

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release      # Web プレビュー
flutter build apk --release      # Android APK
```

- Flutter 3.35.4 / Dart 3.9.2
- Android パッケージ: `com.koji.album`

### ディレクトリ

```
lib/
  main.dart                  アプリ起動・テーマ・Provider 初期化
  theme/app_theme.dart       藍 × 金 × 生成りの配色とタイポグラフィ
  models/gaiji_entry.dart    外字モデル（分類 enum・検索インデックス）
  data/gaiji_repository.dart Hive による端末内保存
  state/gaiji_provider.dart  一覧・検索・絞り込み・並び替え
  services/crop_service.dart 切り取り・余白調整・背景透過
  screens/
    home_shell.dart          下タブ（アルバム／撮影）と撮影フローの制御
    album_screen.dart        一覧・検索・分類チップ
    capture_screen.dart      カメラ／ギャラリーの選択
    crop_editor.dart         切り取り枠（ドラッグ＋四隅ハンドル）
    crop_editor_screen.dart  切り取り画面の枠
    register_screen.dart     名称・読み・分類・出典・メモの入力
    detail_screen.dart       詳細・PNG保存・共有・編集・削除
  widgets/indigo_header.dart 共通ヘッダー
```

---

## データについて

外字の画像は base64 で端末内に保存されます。アプリを削除すると失われるため、
大切な字は詳細画面の「PNG保存」で書き出して保管してください。
