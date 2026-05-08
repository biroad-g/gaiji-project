import 'dart:typed_data';

/// モバイル（Android/iOS）向けスタブ
/// Web用の triggerBrowserDownload は使用しないため何もしない
void triggerBrowserDownload(Uint8List bytes, String fileName) {
  // モバイルでは呼び出されない（呼び出された場合は何もしない）
}
