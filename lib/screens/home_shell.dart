import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../services/crop_service.dart';
import '../theme/app_theme.dart';
import 'album_screen.dart';
import 'capture_screen.dart';
import 'crop_editor_screen.dart';
import 'register_screen.dart';

/// 下タブ（アルバム／撮影）を束ねるシェル。撮影の一連の流れを司る。
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          AlbumScreen(onRequestCapture: () => setState(() => _index = 1)),
          CaptureScreen(onImagePicked: _startCropFlow),
        ],
      ),
      floatingActionButton: _index == 0
          ? Padding(
              // アルバム下部の絞り込みバー（62px）の上に出す
              padding: const EdgeInsets.only(bottom: 68),
              child: FloatingActionButton.extended(
                onPressed: () => setState(() => _index = 1),
                backgroundColor: AppColors.indigo,
                foregroundColor: Colors.white,
                elevation: 3,
                icon: const Icon(Icons.photo_camera_outlined, size: 19),
                label: const Text(
                  '外字を撮影',
                  style: TextStyle(
                    fontFamily: AppTheme.fontSans,
                    fontSize: 13,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: AppColors.gold.withValues(alpha: 0.55)),
                ),
              ),
            )
          : null,
      bottomNavigationBar: _BottomBar(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }

  /// 撮影／読み込みした画像から切り取り → 登録へ進む
  Future<void> _startCropFlow(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (!mounted) return;

    final confirmed = await Navigator.of(context).push<_CropConfirmation>(
      MaterialPageRoute(
        builder: (_) => _CropFlowScreen(
          imageBytes: bytes,
          imageWidth: decoded?.width ?? 0,
          imageHeight: decoded?.height ?? 0,
        ),
      ),
    );

    if (confirmed == null || !mounted) return;

    final registered = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(
          croppedImage: confirmed.croppedImage,
          originalImage: confirmed.originalImage,
        ),
      ),
    );

    if (registered == true && mounted) {
      setState(() => _index = 0);
    }
  }
}

class _CropConfirmation {
  _CropConfirmation(this.croppedImage, this.originalImage);
  final Uint8List croppedImage;
  final Uint8List? originalImage;
}

/// 切り取り処理を実行し、確定した画像を返す画面
class _CropFlowScreen extends StatefulWidget {
  const _CropFlowScreen({
    required this.imageBytes,
    required this.imageWidth,
    required this.imageHeight,
  });

  final Uint8List imageBytes;
  final int imageWidth;
  final int imageHeight;

  @override
  State<_CropFlowScreen> createState() => _CropFlowScreenState();
}

class _CropFlowScreenState extends State<_CropFlowScreen> {
  bool _processing = false;

  Future<void> _onConfirmed(
    Rect pixelRect,
    bool transparentPaper,
    int threshold,
    bool autoTrim,
  ) async {
    setState(() => _processing = true);
    await Future.delayed(const Duration(milliseconds: 40));

    try {
      final result = CropService.crop(
        source: widget.imageBytes,
        left: pixelRect.left.round(),
        top: pixelRect.top.round(),
        right: pixelRect.right.round(),
        bottom: pixelRect.bottom.round(),
        autoTrim: autoTrim,
        transparentPaper: transparentPaper,
        threshold: threshold,
      );

      if (result.width == 0) {
        if (!mounted) return;
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('画像を処理できませんでした。別の写真でお試しください。')),
        );
        return;
      }

      final cropped = CropService.makeThumbnail(result.bytes, maxSide: 900);
      final original =
          CropService.downscaleIfNeeded(widget.imageBytes, maxSide: 1400);

      if (!mounted) return;
      Navigator.of(context).pop(_CropConfirmation(cropped, original));
    } catch (e, st) {
      debugPrint('crop failed: $e\n$st');
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('切り取りに失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CropEditorScreen(
          imageBytes: widget.imageBytes,
          imageWidth: widget.imageWidth,
          imageHeight: widget.imageHeight,
          onConfirmed: _onConfirmed,
        ),
        if (_processing)
          Container(
            color: Colors.black.withValues(alpha: 0.62),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.gold),
                  SizedBox(height: 16),
                  Text(
                    '一字を切り取っています…',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.indigoDeep,
        border: Border(top: BorderSide(color: AppColors.indigoSoft)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'アルバム',
                selected: index == 0,
                onTap: () => onChanged(0),
              ),
              _NavItem(
                icon: Icons.photo_camera_outlined,
                label: '撮影',
                selected: index == 1,
                onTap: () => onChanged(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.goldSoft : Colors.white54;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 21, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                letterSpacing: 1.2,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
