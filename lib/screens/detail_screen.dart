import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/gaiji_entry.dart';
import '../state/gaiji_provider.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';

/// 外字の詳細表示・書き出し・編集・削除
class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.entryId});

  final String entryId;

  Future<void> _exportPng(BuildContext context, GaijiEntry entry) async {
    try {
      final bytes = entry.imageBytes;
      final name = _safeFileName(entry.name);
      final filename = 'gaiji_$name.png';

      if (kIsWeb) {
        // Web ではブラウザのダウンロードに任せる
        await Share.shareXFiles(
          [XFile.fromData(bytes, mimeType: 'image/png', name: filename)],
          text: '外字「${entry.name}」',
        );
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PNGを保存しました: ${file.path}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('書き出しに失敗しました: $e')));
    }
  }

  Future<void> _share(BuildContext context, GaijiEntry entry) async {
    try {
      final name = _safeFileName(entry.name);
      await Share.shareXFiles(
        [
          XFile.fromData(
            entry.imageBytes,
            mimeType: 'image/png',
            name: 'gaiji_$name.png',
          ),
        ],
        text:
            '外字「${entry.name}」${entry.reading.isNotEmpty ? '（${entry.reading}）' : ''}',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('共有できませんでした: $e')));
    }
  }

  static String _safeFileName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[\\/:*?"<>|\s]'), '_');
    return cleaned.isEmpty ? 'gaiji' : cleaned;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GaijiProvider>();
    final entry = provider.all.where((e) => e.id == entryId).firstOrNull;

    if (entry == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppColors.indigo),
        body: const Center(child: Text('この外字は削除されました')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.indigo,
        title: const Text('外字の詳細'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 19),
            tooltip: '編集',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RegisterScreen(
                  croppedImage: entry.imageBytes,
                  editing: entry,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 19),
            tooltip: '削除',
            onPressed: () => _confirmDelete(context, entry),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 24, 20, 24 + MediaQuery.of(context).padding.bottom),
        children: [
          Center(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.line),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.indigo.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Image.memory(entry.imageBytes, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              entry.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTheme.fontSerif,
                fontSize: 28,
                letterSpacing: 4,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          if (entry.reading.isNotEmpty) ...[
            const SizedBox(height: 6),
            Center(
              child: Text(
                entry.reading,
                style: const TextStyle(
                  fontSize: 13,
                  letterSpacing: 2,
                  color: AppColors.inkSoft,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.indigo.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.indigo.withValues(alpha: 0.16)),
              ),
              child: Text(
                '${entry.category.mark}  ${entry.category.label}',
                style: const TextStyle(
                  fontFamily: AppTheme.fontSerif,
                  fontSize: 12,
                  letterSpacing: 1.5,
                  color: AppColors.indigo,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          if (entry.source.isNotEmpty)
            _InfoRow(
              icon: Icons.menu_book_outlined,
              label: '出典',
              value: entry.source,
            ),
          if (entry.memo.isNotEmpty)
            _InfoRow(
              icon: Icons.notes_outlined,
              label: 'メモ',
              value: entry.memo,
            ),
          _InfoRow(
            icon: Icons.event_outlined,
            label: '登録日',
            value:
                '${entry.createdAt.year}年${entry.createdAt.month}月${entry.createdAt.day}日',
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _exportPng(context, entry),
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('PNG保存'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _share(context, entry),
                  icon: const Icon(Icons.ios_share, size: 18),
                  label: const Text('共有'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '透過PNGはWord・お便り・法話資料にそのまま貼れます',
              style: TextStyle(
                fontSize: 10.5,
                color: AppColors.inkFaint.withValues(alpha: 0.95),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, GaijiEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: const Text('この外字を削除しますか？',
            style: TextStyle(fontFamily: AppTheme.fontSerif, fontSize: 17)),
        content: Text(
          '「${entry.name}」をアルバムから削除します。この操作は取り消せません。',
          style: const TextStyle(fontSize: 13, height: 1.7),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('やめる'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('削除する',
                style: TextStyle(color: AppColors.shu)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      HapticFeedback.mediumImpact();
      await context.read<GaijiProvider>().remove(entry.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.gold),
          const SizedBox(width: 12),
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                letterSpacing: 1.0,
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                height: 1.7,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
