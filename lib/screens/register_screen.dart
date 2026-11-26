import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/gaiji_entry.dart';
import '../state/gaiji_provider.dart';
import '../theme/app_theme.dart';

/// 切り取った字形に名前・メモを付けて保存する画面。
/// [editing] を渡すと既存項目の編集になる。
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.croppedImage,
    this.originalImage,
    this.editing,
  });

  final Uint8List croppedImage;
  final Uint8List? originalImage;
  final GaijiEntry? editing;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _readingCtrl;
  late final TextEditingController _sourceCtrl;
  late final TextEditingController _memoCtrl;
  late GaijiCategory _category;
  bool _saving = false;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _readingCtrl = TextEditingController(text: e?.reading ?? '');
    _sourceCtrl = TextEditingController(text: e?.source ?? '');
    _memoCtrl = TextEditingController(text: e?.memo ?? '');
    _category = e?.category ?? GaijiCategory.itaiji;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _readingCtrl.dispose();
    _sourceCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<GaijiProvider>();

    try {
      if (_isEditing) {
        final updated = widget.editing!.copyWith(
          name: _nameCtrl.text.trim(),
          reading: _readingCtrl.text.trim(),
          category: _category,
          source: _sourceCtrl.text.trim(),
          memo: _memoCtrl.text.trim(),
          imageBase64: null,
        );
        await provider.update(GaijiEntry(
          id: updated.id,
          name: updated.name,
          reading: updated.reading,
          category: updated.category,
          source: updated.source,
          memo: updated.memo,
          imageBase64: provider.all
                  .firstWhere((e) => e.id == widget.editing!.id)
                  .imageBase64,
          originalBase64: widget.editing!.originalBase64,
          createdAt: widget.editing!.createdAt,
          updatedAt: DateTime.now(),
        ));
      } else {
        await provider.add(
          name: _nameCtrl.text.trim(),
          reading: _readingCtrl.text.trim(),
          category: _category,
          source: _sourceCtrl.text.trim(),
          memo: _memoCtrl.text.trim(),
          croppedImage: widget.croppedImage,
          originalImage: widget.originalImage,
        );
      }

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? '外字を更新しました' : 'アルバムに登録しました')),
      );
      Navigator.of(context).pop(_isEditing ? false : true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存に失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkered = widget.croppedImage;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.indigo,
        title: Text(_isEditing ? '外字を編集' : '外字を登録'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
          children: [
            // 字形プレビュー
            Center(
              child: Container(
                width: 148,
                height: 148,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.indigo.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(10),
                child: CustomPaint(
                  painter: _CheckerPainter(),
                  child: Image.memory(checkered, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '切り取った字形',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.inkSoft.withValues(alpha: 0.85),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 24),

            _Label('名称', required: true),
            TextFormField(
              controller: _nameCtrl,
              style: const TextStyle(
                  fontFamily: AppTheme.fontSerif, fontSize: 20, letterSpacing: 2),
              decoration: const InputDecoration(
                hintText: '例：觀（観の異体字）',
                counterText: '',
              ),
              maxLength: 24,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '名称を入力してください' : null,
            ),
            const SizedBox(height: 16),

            _Label('読み（任意）'),
            TextFormField(
              controller: _readingCtrl,
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(hintText: '例：かん、ぼだい'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 22),

            _Label('分類'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in GaijiCategory.values)
                  _CategoryChip(
                    category: c,
                    selected: _category == c,
                    onTap: () => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 22),

            _Label('出典（任意）'),
            TextFormField(
              controller: _sourceCtrl,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: '例：『大正蔵』第12巻、〇〇寺 過去帳、版木',
                prefixIcon: Icon(Icons.menu_book_outlined, size: 18),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            _Label('メモ（任意）'),
            TextFormField(
              controller: _memoCtrl,
              style: const TextStyle(fontSize: 14, height: 1.7),
              decoration: const InputDecoration(
                hintText: '用例、気づいたこと、法話で使う場面など',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              minLines: 3,
            ),
            const SizedBox(height: 28),

            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.bookmark_add_outlined, size: 19),
                label: Text(_saving
                    ? '保存しています…'
                    : (_isEditing ? 'この内容で更新' : 'アルバムに登録')),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'すべて端末内に保存されます（オフラインで動作します）',
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppColors.inkFaint.withValues(alpha: 0.95),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.required = false});
  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 1.2,
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (required)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text('*',
                  style: TextStyle(color: AppColors.shu, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final GaijiCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.indigo : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.indigo : AppColors.line,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category.mark,
              style: TextStyle(
                fontFamily: AppTheme.fontSerif,
                fontSize: 13,
                color: selected ? AppColors.goldSoft : AppColors.gold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              category.label,
              style: TextStyle(
                fontSize: 12.5,
                letterSpacing: 0.8,
                color: selected ? Colors.white : AppColors.inkSoft,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 透過画像であることが分かる市松模様
class _CheckerPainter extends CustomPainter {
  static const _cell = 9.0;

  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()..color = const Color(0xFFF7F5EF);
    final dark = Paint()..color = const Color(0xFFEDE9DE);
    canvas.drawRect(Offset.zero & size, light);
    for (double y = 0; y < size.height; y += _cell) {
      for (double x = 0; x < size.width; x += _cell) {
        final isDark = ((x / _cell).floor() + (y / _cell).floor()) % 2 == 0;
        if (isDark) {
          canvas.drawRect(Rect.fromLTWH(x, y, _cell, _cell), dark);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
