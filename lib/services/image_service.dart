import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class ImageService {
  static final ImageService instance = ImageService._internal();
  ImageService._internal();

  final ImagePicker _picker = ImagePicker();
  static const _uuid = Uuid();

  // カメラで撮影
  Future<File?> pickFromCamera() async {
    try {
      final XFile? xfile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (xfile == null) return null;
      if (kIsWeb) {
        // Web: bytes経由でFileライクに扱う
        return _XFileWrapper(xfile) as File?;
      }
      return File(xfile.path);
    } catch (e) {
      debugPrint('Camera error: $e');
      return null;
    }
  }

  // ギャラリーから選択
  Future<File?> pickFromGallery() async {
    try {
      final XFile? xfile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (xfile == null) return null;
      if (kIsWeb) {
        return _XFileWrapper(xfile) as File?;
      }
      return File(xfile.path);
    } catch (e) {
      debugPrint('Gallery error: $e');
      return null;
    }
  }

  // XFile を PickedImage として返す（Web対応版）
  Future<PickedImage?> pickFromCameraAsPickedImage() async {
    try {
      final XFile? xfile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (xfile == null) return null;
      final bytes = await xfile.readAsBytes();
      return PickedImage(bytes: bytes, path: xfile.path, xfile: xfile);
    } catch (e) {
      debugPrint('Camera error: $e');
      return null;
    }
  }

  Future<PickedImage?> pickFromGalleryAsPickedImage() async {
    try {
      final XFile? xfile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (xfile == null) return null;
      final bytes = await xfile.readAsBytes();
      return PickedImage(bytes: bytes, path: xfile.path, xfile: xfile);
    } catch (e) {
      debugPrint('Gallery error: $e');
      return null;
    }
  }

  // 外字画像をアプリ専用ディレクトリに保存（バイト列から）
  Future<SavedImage?> saveGaijiImageFromBytes(Uint8List bytes, {Rect? cropRect, Size? originalSize}) async {
    try {
      Uint8List saveBytes = bytes;

      // クロップ処理（Web・Mobile共通）
      if (cropRect != null && originalSize != null) {
        saveBytes = await _cropBytes(bytes, cropRect, originalSize);
      }

      if (kIsWeb) {
        // Web: メモリに保持（パスなし）
        final id = _uuid.v4();
        return SavedImage(id: id, bytes: saveBytes, path: null);
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        final gaijiDir = Directory(p.join(appDir.path, 'gaiji_images'));
        if (!await gaijiDir.exists()) {
          await gaijiDir.create(recursive: true);
        }
        final fileName = 'gaiji_${_uuid.v4()}.jpg';
        final destPath = p.join(gaijiDir.path, fileName);
        final destFile = File(destPath);
        await destFile.writeAsBytes(saveBytes);
        return SavedImage(id: _uuid.v4(), bytes: saveBytes, path: destPath);
      }
    } catch (e) {
      debugPrint('Save error: $e');
      return null;
    }
  }

  // バイト列をクロップ
  Future<Uint8List> _cropBytes(Uint8List bytes, Rect cropRect, Size originalSize) async {
    try {
      // image パッケージでクロップ
      // クロップ範囲を実際のピクセル座標に変換
      return bytes; // シンプル実装：クロップなしで返す（クロップはUI側で対応）
    } catch (e) {
      debugPrint('Crop error: $e');
      return bytes;
    }
  }

  // 外字画像をアプリ専用ディレクトリに保存（Fileから）
  Future<String?> saveGaijiImage(File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final gaijiDir = Directory(p.join(appDir.path, 'gaiji_images'));
      if (!await gaijiDir.exists()) {
        await gaijiDir.create(recursive: true);
      }
      final fileName = 'gaiji_${_uuid.v4()}.jpg';
      final destPath = p.join(gaijiDir.path, fileName);
      final bytes = await imageFile.readAsBytes();
      final destFile = File(destPath);
      await destFile.writeAsBytes(bytes);
      return destPath;
    } catch (e) {
      debugPrint('Save error: $e');
      return null;
    }
  }

  // 画像ファイルを削除
  Future<void> deleteImage(String? imagePath) async {
    if (imagePath == null || kIsWeb) return;
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Delete error: $e');
    }
  }

  // 外字画像ディレクトリのパスを取得
  Future<String> getGaijiImageDirPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, 'gaiji_images');
  }
}

// 選択した画像を保持するクラス（Web対応）
class PickedImage {
  final Uint8List bytes;
  final String path;
  final XFile xfile;

  PickedImage({required this.bytes, required this.path, required this.xfile});
}

// 保存済み画像の情報（Web対応）
class SavedImage {
  final String id;
  final Uint8List bytes;
  final String? path; // Web では null

  SavedImage({required this.id, required this.bytes, this.path});

  // ストレージパスとして使うキー（Web: id, Mobile: path）
  String get storageKey => path ?? id;
}

// Web用ダミーラッパー（使用しないが型エラー回避用）
class _XFileWrapper {
  final XFile xfile;
  _XFileWrapper(this.xfile);
}
