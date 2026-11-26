import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../widgets/indigo_header.dart';

/// 撮影モード選択画面。
/// カメラで撮影するか、端末の写真から読み込むかを選ぶ。
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key, required this.onImagePicked});

  /// 撮影／読み込みした画像を受け取るコールバック
  final void Function(Uint8List bytes) onImagePicked;

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _picker = ImagePicker();
  bool _busy = false;

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 3000,
        maxHeight: 3000,
        imageQuality: 92,
      );
      if (file == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final bytes = Uint8List.fromList(await file.readAsBytes());
      if (!mounted) return;
      setState(() => _busy = false);
      widget.onImagePicked(bytes);
    } catch (e, st) {
      debugPrint('pick image failed: $e\n$st');
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? 'カメラを起動できませんでした。端末の写真から読み込むか、カメラの使用許可をご確認ください。'
                : '画像を読み込めませんでした。',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const IndigoHeader(
            title: '撮影モード',
            subtitle: 'SHASIN  /  CAPTURE',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BigActionCard(
                    icon: Icons.photo_camera_outlined,
                    title: 'カメラで撮影する',
                    description:
                        '扁額・過去帳・版木・石塔など、漢字が書かれた部分を撮影します。',
                    filled: true,
                    onTap: _busy ? null : () => _pick(ImageSource.camera),
                  ),
                  const SizedBox(height: 14),
                  _BigActionCard(
                    icon: Icons.photo_library_outlined,
                    title: '端末の写真から読み込む',
                    description: 'すでに撮りためた写真から外字を切り取ります。',
                    filled: false,
                    onTap: _busy ? null : () => _pick(ImageSource.gallery),
                  ),
                  const SizedBox(height: 28),
                  _GuideBlock(),
                  if (_busy) ...[
                    const SizedBox(height: 24),
                    const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigActionCard extends StatelessWidget {
  const _BigActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.filled,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : AppColors.indigo;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: filled
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.indigo, AppColors.indigoSoft],
                  )
                : null,
            color: filled ? null : AppColors.paper,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: filled ? AppColors.indigoSoft : AppColors.line,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: filled
                      ? AppColors.gold.withValues(alpha: 0.18)
                      : AppColors.indigo.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: filled
                        ? AppColors.gold.withValues(alpha: 0.4)
                        : AppColors.line,
                  ),
                ),
                child: Icon(icon,
                    color: filled ? AppColors.goldSoft : AppColors.indigo,
                    size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTheme.fontSerif,
                        fontSize: 16,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontFamily: AppTheme.fontSans,
                        fontSize: 11.5,
                        height: 1.6,
                        color: filled
                            ? Colors.white.withValues(alpha: 0.72)
                            : AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: filled
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppColors.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const steps = [
      ('一', '漢字が書かれた部分を撮影します'),
      ('二', '枠を指で動かし、漢字一字を囲みます'),
      ('三', '名称・読み・出典・メモを記入して保存'),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 15, color: AppColors.gold),
              const SizedBox(width: 8),
              Text(
                '使い方',
                style: TextStyle(
                  fontFamily: AppTheme.fontSerif,
                  fontSize: 13.5,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final s in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gold, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      s.$1,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontSerif,
                        fontSize: 12,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        s.$2,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontSans,
                          fontSize: 12.5,
                          height: 1.6,
                          color: AppColors.inkSoft,
                        ),
                      ),
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
