import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'crop_editor.dart';

/// 切り取りツール単体の画面（撮影モードから遷移する）
class CropEditorScreen extends StatelessWidget {
  const CropEditorScreen({
    super.key,
    required this.imageBytes,
    required this.onConfirmed,
    this.imageWidth = 0,
    this.imageHeight = 0,
  });

  final Uint8List imageBytes;
  final int imageWidth;
  final int imageHeight;
  final void Function(
    Rect pixelRect,
    bool transparentPaper,
    int threshold,
    bool autoTrim,
  ) onConfirmed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10151F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10151F),
        title: const Text('切り取り'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: Center(
              child: Text(
                '一字を囲む',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: AppColors.goldSoft,
                ),
              ),
            ),
          ),
        ],
      ),
      body: CropEditor(
        imageBytes: imageBytes,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        onConfirmed: onConfirmed,
      ),
    );
  }
}
