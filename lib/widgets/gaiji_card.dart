import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/gaiji_entry.dart';

class GaijiCard extends StatelessWidget {
  final GaijiEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const GaijiCard({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showOptions(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFD2B48C).withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                child: Container(
                  color: const Color(0xFFFAF5EF),
                  padding: const EdgeInsets.all(6),
                  child: _buildImage(),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF8B4513).withValues(alpha: 0.04),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3A2A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (entry.category != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.category!,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF8B4513)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    // Web: imageBytes を使用
    if (kIsWeb && entry.imageBytes != null) {
      return Image.memory(entry.imageBytes!, fit: BoxFit.contain);
    }
    // Mobile: ファイルパスを使用
    if (!kIsWeb && entry.imagePath.isNotEmpty) {
      final file = File(entry.imagePath);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.contain);
      }
    }
    return const Center(
      child: Icon(Icons.broken_image, color: Colors.grey, size: 32),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
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
            const SizedBox(height: 12),
            Text(
              entry.name,
              style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3A2A1A),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.open_in_new, color: Color(0xFF8B4513)),
              title: const Text('詳細を見る'),
              onTap: () {
                Navigator.pop(ctx);
                onTap();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('削除する', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
