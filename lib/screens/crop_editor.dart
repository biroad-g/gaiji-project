import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 撮った写真から外字一字を囲む切り取りツール。
/// 矩形はドラッグで移動、四隅と四辺のハンドルで大きさを調整できる。
class CropEditor extends StatefulWidget {
  const CropEditor({
    super.key,
    required this.imageBytes,
    required this.onConfirmed,
    this.initialTransparent = true,
    this.imageWidth = 0,
    this.imageHeight = 0,
  });

  final Uint8List imageBytes;
  final bool initialTransparent;

  /// 元画像の実寸（切り取り枠を画像内に限定するため）
  final int imageWidth;
  final int imageHeight;

  /// cropRect は元画像のピクセル座標（left, top, right, bottom）
  final void Function(
    Rect pixelRect,
    bool transparentPaper,
    int threshold,
    bool autoTrim,
  ) onConfirmed;

  @override
  State<CropEditor> createState() => _CropEditorState();
}

enum _Handle { none, move, tl, tr, bl, br, top, bottom, left, right }

class _CropEditorState extends State<CropEditor> {
  Rect _rect = const Rect.fromLTWH(0, 0, 0, 0);
  bool _initialized = false;
  _Handle _active = _Handle.none;
  Offset _dragStart = Offset.zero;
  Rect _rectAtDragStart = Rect.zero;
  Size _canvasSize = Size.zero;

  bool _transparent = true;
  bool _autoTrim = true;
  double _threshold = 150;

  @override
  void initState() {
    super.initState();
    _transparent = widget.initialTransparent;
  }

  double get _minSide => math.min(_imageBox.width, _imageBox.height) * 0.08;

  /// 画面内に BoxFit.contain で表示される画像の矩形
  Rect get _imageBox {
    final cw = _canvasSize.width;
    final ch = _canvasSize.height;
    if (widget.imageWidth <= 0 || widget.imageHeight <= 0) {
      return Rect.fromLTWH(0, 0, cw, ch);
    }
    final scale = math.min(cw / widget.imageWidth, ch / widget.imageHeight);
    final w = widget.imageWidth * scale;
    final h = widget.imageHeight * scale;
    return Rect.fromLTWH((cw - w) / 2, (ch - h) / 2, w, h);
  }

  void _ensureInitialRect(Size canvas) {
    if (_initialized && (_canvasSize.width - canvas.width).abs() < 0.5) {
      return;
    }
    _canvasSize = canvas;
    final box = _imageBox;
    // 画像中央に一文字ぶんの枠を初期配置
    final side = math.min(box.width, box.height) * 0.45;
    _rect = Rect.fromCenter(center: box.center, width: side, height: side);
    _initialized = true;
  }

  /// 元画像ピクセル座標へ変換
  Rect _toPixelRect(Rect displayRect) {
    final box = _imageBox;
    if (box.width <= 0 || box.height <= 0) return displayRect;
    final sx = widget.imageWidth / box.width;
    final sy = widget.imageHeight / box.height;
    return Rect.fromLTRB(
      (displayRect.left - box.left) * sx,
      (displayRect.top - box.top) * sy,
      (displayRect.right - box.left) * sx,
      (displayRect.bottom - box.top) * sy,
    );
  }

  _Handle _hitTest(Offset local) {
    const grab = 32.0;
    final r = _rect;
    bool near(Offset p) => (local - p).distance < grab;

    if (near(r.topLeft)) return _Handle.tl;
    if (near(r.topRight)) return _Handle.tr;
    if (near(r.bottomLeft)) return _Handle.bl;
    if (near(r.bottomRight)) return _Handle.br;
    if (near(Offset(r.center.dx, r.top))) return _Handle.top;
    if (near(Offset(r.center.dx, r.bottom))) return _Handle.bottom;
    if (near(Offset(r.left, r.center.dy))) return _Handle.left;
    if (near(Offset(r.right, r.center.dy))) return _Handle.right;
    if (r.contains(local)) return _Handle.move;
    return _Handle.none;
  }

  void _onPanStart(DragStartDetails d) {
    setState(() {
      _active = _hitTest(d.localPosition);
      _dragStart = d.localPosition;
      _rectAtDragStart = _rect;
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_active == _Handle.none) return;
    final delta = d.localPosition - _dragStart;
    final r = _rectAtDragStart;
    final box = _imageBox;
    final w = box.right;
    final h = box.bottom;
    final minX = box.left;
    final minY = box.top;

    double left = r.left, top = r.top, right = r.right, bottom = r.bottom;

    switch (_active) {
      case _Handle.move:
        left = r.left + delta.dx;
        right = r.right + delta.dx;
        top = r.top + delta.dy;
        bottom = r.bottom + delta.dy;
        // 画像の範囲内に収める
        if (left < minX) {
          right -= (left - minX);
          left = minX;
        }
        if (right > w) {
          left -= (right - w);
          right = w;
        }
        if (top < minY) {
          bottom -= (top - minY);
          top = minY;
        }
        if (bottom > h) {
          top -= (bottom - h);
          bottom = h;
        }
      case _Handle.tl:
        left = (r.left + delta.dx).clamp(minX, r.right - _minSide);
        top = (r.top + delta.dy).clamp(minY, r.bottom - _minSide);
      case _Handle.tr:
        right = (r.right + delta.dx).clamp(r.left + _minSide, w);
        top = (r.top + delta.dy).clamp(minY, r.bottom - _minSide);
      case _Handle.bl:
        left = (r.left + delta.dx).clamp(minX, r.right - _minSide);
        bottom = (r.bottom + delta.dy).clamp(r.top + _minSide, h);
      case _Handle.br:
        right = (r.right + delta.dx).clamp(r.left + _minSide, w);
        bottom = (r.bottom + delta.dy).clamp(r.top + _minSide, h);
      case _Handle.top:
        top = (r.top + delta.dy).clamp(minY, r.bottom - _minSide);
      case _Handle.bottom:
        bottom = (r.bottom + delta.dy).clamp(r.top + _minSide, h);
      case _Handle.left:
        left = (r.left + delta.dx).clamp(minX, r.right - _minSide);
      case _Handle.right:
        right = (r.right + delta.dx).clamp(r.left + _minSide, w);
      case _Handle.none:
        return;
    }

    setState(() {
      _rect = Rect.fromLTRB(left, top, right, bottom);
    });
  }

  void _onPanEnd() {
    setState(() => _active = _Handle.none);
  }

  void _resetRect() {
    setState(() {
      final box = _imageBox;
      final side = math.min(box.width, box.height) * 0.45;
      _rect = Rect.fromCenter(center: box.center, width: side, height: side);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: const Color(0xFF10151F),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final canvas = Size(constraints.maxWidth, constraints.maxHeight);
                _ensureInitialRect(canvas);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: (_) => _onPanEnd(),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(widget.imageBytes, fit: BoxFit.contain),
                      CustomPaint(
                        painter: _CropOverlayPainter(
                          rect: _rect,
                          imageBox: _imageBox,
                        ),
                      ),
                      // 四隅ハンドルの視覚化（タッチは GestureDetector が処理）
                      ..._buildHandles(),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        _buildControls(context),
      ],
    );
  }

  List<Widget> _buildHandles() {
    const size = 18.0;
    Widget dot(Offset p) => Positioned(
          left: p.dx - size / 2,
          top: p.dy - size / 2,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        );

    return [
      dot(_rect.topLeft),
      dot(_rect.topRight),
      dot(_rect.bottomLeft),
      dot(_rect.bottomRight),
    ];
  }

  Widget _buildControls(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.crop_free,
                      size: 18, color: AppColors.indigo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '漢字一字を枠で囲んでください',
                      style: TextStyle(
                        fontFamily: AppTheme.fontSans,
                        fontSize: 12.5,
                        color: AppColors.inkSoft.withValues(alpha: 0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _resetRect,
                    icon: const Icon(Icons.restart_alt, size: 16),
                    label: const Text('リセット',
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _ToggleChip(
                      label: '背景を透過',
                      value: _transparent,
                      onChanged: (v) => setState(() => _transparent = v),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ToggleChip(
                      label: '余白を自動調整',
                      value: _autoTrim,
                      onChanged: (v) => setState(() => _autoTrim = v),
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.topCenter,
                child: _transparent
                    ? Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Text('墨の濃さ',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.inkSoft)),
                            Expanded(
                              child: Slider(
                                value: _threshold,
                                min: 80,
                                max: 210,
                                activeColor: AppColors.gold,
                                inactiveColor: AppColors.line,
                                onChanged: (v) =>
                                    setState(() => _threshold = v),
                              ),
                            ),
                            SizedBox(
                              width: 32,
                              child: Text(
                                _threshold.round().toString(),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.inkSoft),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('やり直す'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        widget.onConfirmed(
                          _toPixelRect(_rect),
                          _transparent,
                          _threshold.round(),
                          _autoTrim,
                        );
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('この範囲で切り取る'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value
              ? AppColors.indigo.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? AppColors.indigo : AppColors.line,
            width: value ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: value ? AppColors.indigo : AppColors.inkFaint,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontFamily: AppTheme.fontSans,
                  color: value ? AppColors.indigo : AppColors.inkSoft,
                  fontWeight: value ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  _CropOverlayPainter({required this.rect, required this.imageBox});

  final Rect rect;
  final Rect imageBox;

  @override
  void paint(Canvas canvas, Size size) {
    if (rect.isEmpty) return;

    // 外側を暗く
    final overlay = Paint()..color = Colors.black.withValues(alpha: 0.55);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRect(rect),
      ),
      overlay,
    );
    canvas.restore();

    // 枠線（金）
    final border = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(rect, border);

    // 三分割のガイド線
    final guide = Paint()
      ..color = Colors.white.withValues(alpha: 0.30)
      ..strokeWidth = 0.8;
    for (int i = 1; i <= 2; i++) {
      final dx = rect.left + rect.width * i / 3;
      final dy = rect.top + rect.height * i / 3;
      canvas.drawLine(Offset(dx, rect.top), Offset(dx, rect.bottom), guide);
      canvas.drawLine(Offset(rect.left, dy), Offset(rect.right, dy), guide);
    }
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter old) =>
      old.rect != rect || old.imageBox != imageBox;
}
