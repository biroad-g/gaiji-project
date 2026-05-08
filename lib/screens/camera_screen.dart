import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../services/image_service.dart';
import '../services/database_service.dart';
import '../models/gaiji_entry.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  PickedImage? _pickedImage;
  Uint8List? _croppedBytes;
  // Rect? _cropRect; // 将来のクロップ精度向上に使用予定
  final _nameController = TextEditingController();
  final _memoController = TextEditingController();
  String? _selectedCategory;
  static const List<String> _presetCategories = [
    '仏教用語', '人名', '地名', '戒名', '法名', 'その他',
  ];
  bool _isSaving = false;
  int _step = 0; // 0:撮影, 1:トリミング, 2:情報入力

  @override
  void dispose() {
    _nameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  // ステップ1: カメラで撮影
  Future<void> _takePhoto() async {
    final picked = await ImageService.instance.pickFromCameraAsPickedImage();
    if (picked != null) {
      setState(() {
        _pickedImage = picked;
        _croppedBytes = picked.bytes;
        _step = 1;
      });
    }
  }

  // ステップ1（代替）: ギャラリーから選択
  Future<void> _pickFromGallery() async {
    final picked = await ImageService.instance.pickFromGalleryAsPickedImage();
    if (picked != null) {
      setState(() {
        _pickedImage = picked;
        _croppedBytes = picked.bytes;
        _step = 1;
      });
    }
  }

  // ステップ3: 保存
  Future<void> _saveGaiji() async {
    if (_croppedBytes == null) return;
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
      final saved = await ImageService.instance.saveGaijiImageFromBytes(_croppedBytes!);
      if (saved == null) throw Exception('画像の保存に失敗しました');

      final entry = GaijiEntry(
        name: _nameController.text.trim(),
        imagePath: saved.storageKey,
        memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
        createdAt: DateTime.now(),
        category: _selectedCategory,
      );
      entry.imageBytes = saved.bytes;

      await DatabaseService.instance.insertEntry(entry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${entry.name}」を登録しました'),
            backgroundColor: const Color(0xFF8B4513),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5EF),
      appBar: AppBar(
        title: Text(
          _step == 0
              ? '⑴ 写真を撮る'
              : _step == 1
                  ? '⑵ 漢字を切り取る'
                  : '⑶ 情報を入力する',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step -= 1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _step == 0
          ? _buildStep0()
          : _step == 1
              ? _buildStep1()
              : _buildStep2(),
    );
  }

  // ステップ0: 撮影方法選択
  Widget _buildStep0() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF8B4513).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF8B4513).withValues(alpha: 0.2)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF8B4513), size: 20),
                    SizedBox(width: 8),
                    Text(
                      '使い方',
                      style: TextStyle(
                        color: Color(0xFF8B4513),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                _StepGuideItem(step: '①', text: '漢字が書かれた部分を撮影する'),
                SizedBox(height: 6),
                _StepGuideItem(step: '②', text: '切り取りツールで漢字一字を切り取る'),
                SizedBox(height: 6),
                _StepGuideItem(step: '③', text: '名前・メモを入力して保存する'),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _BigActionButton(
            icon: Icons.camera_alt,
            label: 'カメラで撮影する',
            subLabel: '今すぐ漢字を撮る',
            color: const Color(0xFF8B4513),
            onTap: _takePhoto,
          ),
          const SizedBox(height: 20),
          _BigActionButton(
            icon: Icons.photo_library,
            label: 'アルバムから選ぶ',
            subLabel: '既存の写真を使う',
            color: const Color(0xFF5D7A6B),
            onTap: _pickFromGallery,
          ),
        ],
      ),
    );
  }

  // ステップ1: トリミング
  Widget _buildStep1() {
    if (_pickedImage == null) return const SizedBox();
    return _CropWidget(
      imageBytes: _pickedImage!.bytes,
      onCropped: (cropped) {
        setState(() {
          _croppedBytes = cropped;
          _step = 2;
        });
      },
    );
  }

  // ステップ2: 情報入力
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 切り取り画像プレビュー
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF8B4513), width: 2),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _croppedBytes != null
                    ? Image.memory(_croppedBytes!, fit: BoxFit.contain)
                    : const Icon(Icons.image, size: 40, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _LabelText(label: '名前・読み方（必須）'),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            decoration: _inputDecoration(
              hint: '例：たい（𥊙）、戒名など',
              icon: Icons.edit,
            ),
            maxLength: 30,
          ),
          const SizedBox(height: 16),
          const _LabelText(label: 'カテゴリ'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetCategories.map((cat) {
              final selected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = selected ? null : cat;
                  });
                },
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const _LabelText(label: 'メモ（任意）'),
          const SizedBox(height: 6),
          TextField(
            controller: _memoController,
            decoration: _inputDecoration(
              hint: '読み方・出典・用途など',
              icon: Icons.notes,
            ),
            maxLines: 3,
            maxLength: 200,
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveGaiji,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(
              _isSaving ? '保存中...' : '外字として登録する',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
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
}

// ============================================================
// カスタムトリミングウィジェット（Web/Mobile共通）
// ============================================================
class _CropWidget extends StatefulWidget {
  final Uint8List imageBytes;
  final void Function(Uint8List cropped) onCropped;

  const _CropWidget({required this.imageBytes, required this.onCropped});

  @override
  State<_CropWidget> createState() => _CropWidgetState();
}

class _CropWidgetState extends State<_CropWidget> {
  // クロップ選択領域（正規化 0.0〜1.0）
  double _left = 0.1;
  double _top = 0.1;
  double _right = 0.9;
  double _bottom = 0.9;

  Offset? _dragStart;
  String? _dragHandle; // 'tl','tr','bl','br','move'

  // LayoutBuilder で取得した画像表示エリアのサイズ（_applyCrop で使用）
  Size _cropAreaSize = Size.zero;

  static const double _handleSize = 24.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '漢字の部分をドラッグして切り取り範囲を選択してください',
            style: TextStyle(
              color: const Color(0xFF8B4513).withValues(alpha: 0.8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              // サイズを保存（_applyCrop での BoxFit.contain 計算に使用）
              if (_cropAreaSize.width != w || _cropAreaSize.height != h) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _cropAreaSize = Size(w, h));
                });
              }
              return GestureDetector(
                onPanStart: (d) => _onPanStart(d, w, h),
                onPanUpdate: (d) => _onPanUpdate(d, w, h),
                onPanEnd: (_) => setState(() => _dragStart = null),
                child: Stack(
                  children: [
                    // 元画像
                    Positioned.fill(
                      child: Image.memory(widget.imageBytes, fit: BoxFit.contain),
                    ),
                    // 暗転オーバーレイ（クロップ外）
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CropOverlayPainter(
                          left: _left * w,
                          top: _top * h,
                          right: _right * w,
                          bottom: _bottom * h,
                        ),
                      ),
                    ),
                    // ハンドル
                    ..._buildHandles(w, h),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _left = 0.1; _top = 0.1; _right = 0.9; _bottom = 0.9;
                  }),
                  icon: const Icon(Icons.refresh, color: Color(0xFF8B4513)),
                  label: const Text('リセット', style: TextStyle(color: Color(0xFF8B4513))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF8B4513)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _applyCrop,
                  icon: const Icon(Icons.crop),
                  label: const Text(
                    'この範囲で切り取る',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildHandles(double w, double h) {
    final l = _left * w;
    final t = _top * h;
    final r = _right * w;
    final b = _bottom * h;
    const hs = _handleSize;

    return [
      // 角ハンドル
      _handle(l - hs / 2, t - hs / 2, 'tl'),
      _handle(r - hs / 2, t - hs / 2, 'tr'),
      _handle(l - hs / 2, b - hs / 2, 'bl'),
      _handle(r - hs / 2, b - hs / 2, 'br'),
      // 境界線
      Positioned(
        left: l, top: t,
        width: r - l, height: b - t,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    ];
  }

  Widget _handle(double x, double y, String name) {
    return Positioned(
      left: x, top: y,
      width: _handleSize, height: _handleSize,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF8B4513),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails d, double w, double h) {
    final x = d.localPosition.dx;
    final y = d.localPosition.dy;
    final l = _left * w;
    final t = _top * h;
    final r = _right * w;
    final b = _bottom * h;
    const hs = _handleSize;

    String? handle;
    if ((x - l).abs() < hs && (y - t).abs() < hs) {
      handle = 'tl';
    } else if ((x - r).abs() < hs && (y - t).abs() < hs) {
      handle = 'tr';
    } else if ((x - l).abs() < hs && (y - b).abs() < hs) {
      handle = 'bl';
    } else if ((x - r).abs() < hs && (y - b).abs() < hs) {
      handle = 'br';
    } else if (x > l && x < r && y > t && y < b) {
      handle = 'move';
    }
    setState(() {
      _dragHandle = handle;
      _dragStart = d.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails d, double w, double h) {
    if (_dragHandle == null || _dragStart == null) return;
    final dx = d.delta.dx / w;
    final dy = d.delta.dy / h;

    setState(() {
      switch (_dragHandle) {
        case 'tl':
          _left = (_left + dx).clamp(0.0, _right - 0.05);
          _top = (_top + dy).clamp(0.0, _bottom - 0.05);
          break;
        case 'tr':
          _right = (_right + dx).clamp(_left + 0.05, 1.0);
          _top = (_top + dy).clamp(0.0, _bottom - 0.05);
          break;
        case 'bl':
          _left = (_left + dx).clamp(0.0, _right - 0.05);
          _bottom = (_bottom + dy).clamp(_top + 0.05, 1.0);
          break;
        case 'br':
          _right = (_right + dx).clamp(_left + 0.05, 1.0);
          _bottom = (_bottom + dy).clamp(_top + 0.05, 1.0);
          break;
        case 'move':
          final newL = (_left + dx).clamp(0.0, 1.0 - (_right - _left));
          final newT = (_top + dy).clamp(0.0, 1.0 - (_bottom - _top));
          _right = newL + (_right - _left);
          _bottom = newT + (_bottom - _top);
          _left = newL;
          _top = newT;
          break;
      }
    });
  }

  Future<void> _applyCrop() async {
    // ① 元画像をデコードしてピクセルサイズを取得
    final decoded = img.decodeImage(widget.imageBytes);
    if (decoded == null) {
      widget.onCropped(widget.imageBytes);
      return;
    }
    final imgW = decoded.width.toDouble();
    final imgH = decoded.height.toDouble();

    // ② LayoutBuilder で保存した画像表示エリアのサイズを使用
    //    (_left/_top/_right/_bottom は w×h に対する正規化値)
    final w = _cropAreaSize.width;
    final h = _cropAreaSize.height;

    if (w <= 0 || h <= 0) {
      widget.onCropped(widget.imageBytes);
      return;
    }

    // ③ BoxFit.contain のレターボックスオフセットを計算
    //    画像アスペクト比とウィジェットアスペクト比を比較して
    //    実際に画像が描画される矩形 (renderedRect) を求める
    final widgetAspect = w / h;
    final imageAspect = imgW / imgH;

    double renderedW, renderedH, offsetX, offsetY;
    if (imageAspect > widgetAspect) {
      // 横長画像 → 横幅フィット、上下にレターボックス
      renderedW = w;
      renderedH = w / imageAspect;
      offsetX = 0;
      offsetY = (h - renderedH) / 2;
    } else {
      // 縦長画像 → 縦幅フィット、左右にレターボックス
      renderedH = h;
      renderedW = h * imageAspect;
      offsetX = (w - renderedW) / 2;
      offsetY = 0;
    }

    // ④ 正規化ウィジェット座標 → 画像ピクセル座標に変換
    //    _left/_top 等は w×h 全体に対する正規化値
    //    まずウィジェットピクセル座標に戻し、レターボックス分を引いて
    //    renderedW×renderedH に対する相対位置を求め、imgW×imgH にスケーリング
    double selLeft   = _left   * w;
    double selTop    = _top    * h;
    double selRight  = _right  * w;
    double selBottom = _bottom * h;

    // レターボックスオフセットを除去（rendered image 内の座標に変換）
    selLeft   = (selLeft   - offsetX).clamp(0.0, renderedW);
    selTop    = (selTop    - offsetY).clamp(0.0, renderedH);
    selRight  = (selRight  - offsetX).clamp(0.0, renderedW);
    selBottom = (selBottom - offsetY).clamp(0.0, renderedH);

    // 画像ピクセル座標にスケーリング
    final px = (selLeft   / renderedW * imgW).round().clamp(0, decoded.width  - 1);
    final py = (selTop    / renderedH * imgH).round().clamp(0, decoded.height - 1);
    final pw = ((selRight  - selLeft) / renderedW * imgW).round()
                 .clamp(1, decoded.width  - px);
    final ph = ((selBottom - selTop)  / renderedH * imgH).round()
                 .clamp(1, decoded.height - py);

    // ⑤ クロップ実行
    final cropped = img.copyCrop(decoded, x: px, y: py, width: pw, height: ph);

    // ⑥ PNG エンコードして返す
    final croppedBytes = Uint8List.fromList(img.encodePng(cropped));
    widget.onCropped(croppedBytes);
  }
}

// クロップ選択オーバーレイ描画
class _CropOverlayPainter extends CustomPainter {
  final double left, top, right, bottom;
  _CropOverlayPainter({
    required this.left, required this.top,
    required this.right, required this.bottom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    // 上
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), paint);
    // 下
    canvas.drawRect(Rect.fromLTWH(0, bottom, size.width, size.height - bottom), paint);
    // 左
    canvas.drawRect(Rect.fromLTWH(0, top, left, bottom - top), paint);
    // 右
    canvas.drawRect(Rect.fromLTWH(right, top, size.width - right, bottom - top), paint);
  }

  @override
  bool shouldRepaint(_CropOverlayPainter old) =>
      old.left != left || old.top != top || old.right != right || old.bottom != bottom;
}

// ============================================================
// ヘルパーウィジェット
// ============================================================
class _StepGuideItem extends StatelessWidget {
  final String step;
  final String text;
  const _StepGuideItem({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFF8B4513),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(color: Color(0xFF5A4A3A), fontSize: 14)),
        ),
      ],
    );
  }
}

class _BigActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subLabel;
  final Color color;
  final VoidCallback onTap;

  const _BigActionButton({
    required this.icon,
    required this.label,
    required this.subLabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 36),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.bold, letterSpacing: 1,
                  ),
                ),
                Text(subLabel, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }
}

class _LabelText extends StatelessWidget {
  final String label;
  const _LabelText({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14, fontWeight: FontWeight.bold,
        color: Color(0xFF5A4A3A), letterSpacing: 0.5,
      ),
    );
  }
}
