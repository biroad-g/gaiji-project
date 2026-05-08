import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../models/gaiji_entry.dart';
import '../services/database_service.dart';
import '../services/image_service.dart';
import '../services/download_service.dart';

class DetailScreen extends StatefulWidget {
  final GaijiEntry entry;

  const DetailScreen({super.key, required this.entry});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late GaijiEntry _entry;
  final _nameController = TextEditingController();
  final _memoController = TextEditingController();
  String? _selectedCategory;
  bool _isEditing = false;
  bool _isSaving = false;

  final List<String> _presetCategories = [
    '仏教用語', '人名', '地名', '戒名', '法名', 'その他',
  ];

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _nameController.text = _entry.name;
    _memoController.text = _entry.memo ?? '';
    _selectedCategory = _entry.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  // 画像を共有
  Future<void> _shareImage() async {
    try {
      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Web環境では共有機能は使えません')),
        );
        return;
      }
      final file = XFile(_entry.imagePath);
      await Share.shareXFiles(
        [file],
        text: '外字：${_entry.name}',
        subject: '外字画像',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('共有に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // -------------------------------------------------------
  // JPEGとしてエクスポート
  // Web  : ブラウザのダウンロードダイアログで保存
  // Mobile: 一時ファイルに書き出し share_plus で共有
  // -------------------------------------------------------
  Future<void> _exportAsJpeg() async {
    // ① 元バイト列を取得
    Uint8List? sourceBytes;
    if (kIsWeb) {
      sourceBytes = _entry.imageBytes;
    } else if (_entry.imagePath.isNotEmpty) {
      final f = File(_entry.imagePath);
      if (f.existsSync()) sourceBytes = await f.readAsBytes();
    }
    // imageBytes フォールバック
    sourceBytes ??= _entry.imageBytes;

    if (sourceBytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('画像データが見つかりません'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // ② 処理中インジケーター表示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('JPEGに変換中...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );
    }

    try {
      // ③ PNG/任意形式 → JPEG 変換（品質85）
      final decoded = img.decodeImage(sourceBytes);
      if (decoded == null) throw Exception('画像のデコードに失敗しました');
      final jpegBytes = Uint8List.fromList(
        img.encodeJpg(decoded, quality: 85),
      );

      // ファイル名: "{名前}_{YYYYMMDD}.jpg"
      final dateStr =
          '${_entry.createdAt.year}'
          '${_entry.createdAt.month.toString().padLeft(2, '0')}'
          '${_entry.createdAt.day.toString().padLeft(2, '0')}';
      // ファイル名に使えない文字を除去
      final safeName = _entry.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final fileName = '${safeName}_$dateStr.jpg';

      if (kIsWeb) {
        // ④-A Web: ブラウザのダウンロードダイアログ
        triggerBrowserDownload(jpegBytes, fileName);
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('「$fileName」をダウンロードしました'),
              backgroundColor: const Color(0xFF5D7A6B),
            ),
          );
        }
      } else {
        // ④-B Mobile: 一時ファイルに保存して share_plus で共有
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/$fileName';
        await File(filePath).writeAsBytes(jpegBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
        await Share.shareXFiles(
          [XFile(filePath, mimeType: 'image/jpeg')],
          text: '外字：${_entry.name}',
          subject: '外字画像 ($fileName)',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エクスポートに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 情報を保存
  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('名前・読み方を入力してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final updated = _entry.copyWith(
        name: _nameController.text.trim(),
        memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
        category: _selectedCategory,
      );
      await DatabaseService.instance.updateEntry(updated);
      setState(() {
        _entry = updated;
        _isEditing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('更新しました'),
            backgroundColor: Color(0xFF8B4513),
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // 画像を再撮影・差し替え
  Future<void> _replaceImage() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '画像を差し替える',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF8B4513)),
                title: const Text('カメラで撮影'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF5D7A6B)),
              title: const Text('アルバムから選択'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (result == null) return;

    PickedImage? pickedImage;
    if (result == 'camera') {
      pickedImage = await ImageService.instance.pickFromCameraAsPickedImage();
    } else {
      pickedImage = await ImageService.instance.pickFromGalleryAsPickedImage();
    }
    if (pickedImage == null) return;
    if (!mounted) return;

    final saved = await ImageService.instance.saveGaijiImageFromBytes(pickedImage.bytes);
    if (saved == null) return;

    // 旧画像削除（Mobile のみ）
    await ImageService.instance.deleteImage(_entry.imagePath);

    final updated = _entry.copyWith(
      imagePath: saved.storageKey,
      imageBytes: saved.bytes,
    );
    await DatabaseService.instance.updateEntry(updated);
    setState(() => _entry = updated);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('画像を更新しました'),
        backgroundColor: Color(0xFF8B4513),
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5EF),
      appBar: AppBar(
        title: Text(_isEditing ? '編集中' : _entry.name),
        actions: [
          if (!_isEditing) ...[
            // JPEGエクスポートボタン（Web: ダウンロード / Mobile: 共有）
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: kIsWeb ? 'JPEGでダウンロード' : 'JPEGで共有・保存',
              onPressed: _exportAsJpeg,
            ),
            if (!kIsWeb)
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: '共有',
                onPressed: _shareImage,
              ),
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: '編集',
              onPressed: () => setState(() => _isEditing = true),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'キャンセル',
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _nameController.text = _entry.name;
                  _memoController.text = _entry.memo ?? '';
                  _selectedCategory = _entry.category;
                });
              },
            ),
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              tooltip: '保存',
              onPressed: _isSaving ? null : _saveChanges,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageSection(),
            const SizedBox(height: 24),
            _isEditing ? _buildEditSection() : _buildViewSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 260,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF8B4513), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _buildImageWidget(),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _replaceImage,
          icon: const Icon(Icons.swap_horiz, color: Color(0xFF8B4513), size: 18),
          label: const Text(
            '画像を差し替える',
            style: TextStyle(color: Color(0xFF8B4513), fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildImageWidget() {
    // Web: imageBytes
    if (kIsWeb && _entry.imageBytes != null) {
      return Image.memory(_entry.imageBytes!, fit: BoxFit.contain);
    }
    // Mobile: ファイルパス
    if (!kIsWeb && _entry.imagePath.isNotEmpty) {
      final file = File(_entry.imagePath);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.contain);
      }
    }
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 60, color: Colors.grey),
          SizedBox(height: 8),
          Text('画像が見つかりません', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildViewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoCard(icon: Icons.text_fields, label: '名前・読み方', value: _entry.name),
        const SizedBox(height: 12),
        if (_entry.category != null) ...[
          _InfoCard(icon: Icons.category, label: 'カテゴリ', value: _entry.category!),
          const SizedBox(height: 12),
        ],
        if (_entry.memo != null && _entry.memo!.isNotEmpty) ...[
          _InfoCard(icon: Icons.notes, label: 'メモ', value: _entry.memo!),
          const SizedBox(height: 12),
        ],
        _InfoCard(
          icon: Icons.calendar_today,
          label: '登録日時',
          value: _formatDate(_entry.createdAt),
        ),
        const SizedBox(height: 24),
        // JPEGエクスポートボタン（Web: ダウンロード / Mobile: 共有）
        ElevatedButton.icon(
          onPressed: _exportAsJpeg,
          icon: const Icon(Icons.download),
          label: const Text(
            kIsWeb ? 'JPEGでダウンロード（PCに保存）' : 'JPEGで共有・保存',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: const Color(0xFF8B4513),
          ),
        ),
        if (!kIsWeb) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _shareImage,
            icon: const Icon(Icons.share, color: Color(0xFF5D7A6B)),
            label: const Text(
              '他のアプリへ共有',
              style: TextStyle(fontSize: 14, color: Color(0xFF5D7A6B)),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Color(0xFF5D7A6B)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEditSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '名前・読み方（必須）',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF5A4A3A)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          decoration: _inputDecoration(hint: '名前・読み方', icon: Icons.edit),
          maxLength: 30,
        ),
        const SizedBox(height: 16),
        const Text(
          'カテゴリ',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF5A4A3A)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetCategories.map((cat) {
            final selected = _selectedCategory == cat;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedCategory = selected ? null : cat;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF8B4513)
                      : const Color(0xFF8B4513).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF8B4513).withValues(alpha: 0.3)),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF8B4513),
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const Text(
          'メモ（任意）',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF5A4A3A)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _memoController,
          decoration: _inputDecoration(hint: 'メモを入力', icon: Icons.notes),
          maxLines: 3,
          maxLength: 200,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveChanges,
          icon: const Icon(Icons.save),
          label: const Text(
            '変更を保存する',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFAA9988)),
      prefixIcon: Icon(icon, color: const Color(0xFF8B4513), size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD2B48C)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD2B48C)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF8B4513), width: 2),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}年${dt.month}月${dt.day}日 '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD2B48C).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF8B4513), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11, color: Color(0xFFAA9988), fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15, color: Color(0xFF3A2A1A), fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
