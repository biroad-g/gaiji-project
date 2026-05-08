import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Web 向け: ブラウザのダウンロードダイアログを起動する
void triggerBrowserDownload(Uint8List bytes, String fileName) {
  // Uint8List → JS の Uint8Array に変換
  final jsArray = bytes.toJS;
  final blob = web.Blob(
    [jsArray.dartify() as JSAny].toJS,
    web.BlobPropertyBag(type: 'image/jpeg'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = fileName;
  anchor.style.display = 'none';
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
