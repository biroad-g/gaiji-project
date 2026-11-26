import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gaiji_entry.dart';
import '../state/gaiji_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/indigo_header.dart';
import 'detail_screen.dart';

/// 外字アルバムの一覧画面（メイン）
class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key, this.onRequestCapture});

  /// 撮影タブへ移動するためのコールバック
  final VoidCallback? onRequestCapture;

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  final _searchCtrl = TextEditingController();
  bool _searchOpen = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GaijiProvider>();
    final items = provider.visible;

    return Scaffold(
      body: Column(
        children: [
          IndigoHeader(
            title: '古字アルバム',
            subtitle: 'K O J I   A R U B A M U',
            trailing: Row(
              children: [
                _HeaderIconButton(
                  icon: _searchOpen ? Icons.close : Icons.search,
                  onTap: () {
                    setState(() => _searchOpen = !_searchOpen);
                    if (!_searchOpen) {
                      _searchCtrl.clear();
                      provider.search('');
                    }
                  },
                ),
              ],
            ),
          ),
          if (_searchOpen)
            _SearchBar(
              controller: _searchCtrl,
              onChanged: provider.search,
            ),
          Expanded(
            child: provider.loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.gold))
                : items.isEmpty
                    ? _EmptyState(
                        hasQuery: provider.query.isNotEmpty ||
                            provider.categoryFilter != null,
                        total: provider.total,
                      )
                    : _buildGrid(context, items),
          ),
          if (provider.total > 0) _buildFooter(provider),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<GaijiEntry> items) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.87,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _GaijiCard(entry: items[i]),
    );
  }

  Widget _buildFooter(GaijiProvider provider) {
    final cats = provider.countsByCategory;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            children: [
              _FilterPill(
                label: 'すべて',
                count: provider.total,
                selected: provider.categoryFilter == null,
                onTap: () => provider.filterCategory(null),
              ),
              for (final c in GaijiCategory.values)
                if ((cats[c] ?? 0) > 0 || provider.categoryFilter == c)
                  _FilterPill(
                    label: c.label,
                    mark: c.mark,
                    count: cats[c] ?? 0,
                    selected: provider.categoryFilter == c,
                    onTap: () => provider.filterCategory(
                        provider.categoryFilter == c ? null : c),
                  ),
              _SortPill(
                order: provider.sortOrder,
                onChanged: provider.setSortOrder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.28), width: 1),
        ),
        child: Icon(icon, size: 19, color: AppColors.goldSoft),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.indigo,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: TextField(
        controller: controller,
        autofocus: true,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, color: AppColors.ink),
        decoration: InputDecoration(
          isDense: true,
          hintText: '名称・読み・出典・メモから検索',
          fillColor: Colors.white.withValues(alpha: 0.97),
          prefixIcon: const Icon(Icons.search, size: 18),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _GaijiCard extends StatelessWidget {
  const _GaijiCard({required this.entry});
  final GaijiEntry entry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DetailScreen(entryId: entry.id)),
        ),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
            boxShadow: [
              BoxShadow(
                color: AppColors.indigo.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.line),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Image.memory(
                          entry.imageBytes,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.indigo.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          entry.category.mark,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontSerif,
                            fontSize: 10,
                            color: AppColors.goldSoft,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontSerif,
                        fontSize: 15,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.reading.isNotEmpty ? entry.reading : entry.category.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.inkSoft,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.mark,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final String? mark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.indigo : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected ? AppColors.indigo : AppColors.line),
          ),
          child: Row(
            children: [
              if (mark != null) ...[
                Text(
                  mark!,
                  style: TextStyle(
                    fontFamily: AppTheme.fontSerif,
                    fontSize: 11,
                    color: selected ? AppColors.goldSoft : AppColors.gold,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  letterSpacing: 0.6,
                  color: selected ? Colors.white : AppColors.inkSoft,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.65)
                      : AppColors.inkFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortPill extends StatelessWidget {
  const _SortPill({required this.order, required this.onChanged});
  final SortOrder order;
  final ValueChanged<SortOrder> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortOrder>(
      onSelected: onChanged,
      tooltip: '並び替え',
      itemBuilder: (_) => [
        for (final o in SortOrder.values)
          PopupMenuItem(
            value: o,
            child: Row(
              children: [
                Icon(
                  o == order
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 16,
                  color: o == order ? AppColors.gold : AppColors.inkFaint,
                ),
                const SizedBox(width: 10),
                Text(o.label, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            const Icon(Icons.swap_vert, size: 14, color: AppColors.inkSoft),
            const SizedBox(width: 6),
            Text(
              order.label,
              style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasQuery, required this.total});
  final bool hasQuery;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (hasQuery && total > 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 36, color: AppColors.inkFaint),
            const SizedBox(height: 14),
            Text('該当する外字が見つかりません',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.inkSoft.withValues(alpha: 0.9))),
          ],
        ),
      );
    }
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 108,
              height: 108,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.line, width: 1.2),
                color: AppColors.paper,
              ),
              child: const Text(
                '字',
                style: TextStyle(
                  fontFamily: AppTheme.fontSerif,
                  fontSize: 44,
                  color: AppColors.gold,
                ),
              ),
            ),
            const SizedBox(height: 26),
            const Text(
              'まだ外字がありません',
              style: TextStyle(
                fontFamily: AppTheme.fontSerif,
                fontSize: 18,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '扁額・過去帳・版木・石塔など、\n漢字が書かれた部分を撮影して、\n一字ずつ切り取って登録してください。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.9,
                color: AppColors.inkSoft.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
