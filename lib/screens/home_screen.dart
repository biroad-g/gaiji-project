import 'package:flutter/material.dart';
import '../models/gaiji_entry.dart';
import '../services/database_service.dart';
import '../services/image_service.dart';
import '../widgets/gaiji_card.dart';
import 'camera_screen.dart';
import 'detail_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<GaijiEntry> _filteredEntries = [];
  String? _selectedCategory;
  List<String> _categories = [];
  bool _isLoading = false;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    try {
      final entries = _selectedCategory == null
          ? await DatabaseService.instance.getAllEntries()
          : await DatabaseService.instance.getEntriesByCategory(_selectedCategory!);
      final categories = await DatabaseService.instance.getCategories();
      final count = await DatabaseService.instance.getTotalCount();
      setState(() {
        _filteredEntries = entries;
        _categories = categories;
        _totalCount = count;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onAddPressed() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
    if (result == true) {
      await _loadEntries();
    }
  }

  Future<void> _onEntryTap(GaijiEntry entry) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(entry: entry)),
    );
    if (result == true) {
      await _loadEntries();
    }
  }

  Future<void> _onDeleteEntry(GaijiEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除の確認'),
        content: Text('「${entry.name}」を削除しますか？'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirm == true && entry.id != null) {
      await DatabaseService.instance.deleteEntry(entry.id!);
      await ImageService.instance.deleteImage(entry.imagePath);
      await _loadEntries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${entry.name}」を削除しました'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _onSearchPressed() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
    if (result == true) {
      await _loadEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5EF),
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('⛩ ', style: TextStyle(fontSize: 20)),
            Text('外字登録'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '検索',
            onPressed: _onSearchPressed,
          ),
        ],
      ),
      body: Column(
        children: [
          // ヘッダー統計バー
          _buildStatsBar(),
          // カテゴリフィルター
          if (_categories.isNotEmpty) _buildCategoryFilter(),
          // 外字一覧
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF8B4513),
                    ),
                  )
                : _filteredEntries.isEmpty
                    ? _buildEmptyState()
                    : _buildGaijiGrid(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddPressed,
        icon: const Icon(Icons.add_a_photo),
        label: const Text(
          '外字を追加',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF8B4513).withValues(alpha: 0.08),
      child: Row(
        children: [
          const Icon(Icons.collections, color: Color(0xFF8B4513), size: 18),
          const SizedBox(width: 8),
          Text(
            '登録外字数：$_totalCount 字',
            style: const TextStyle(
              color: Color(0xFF8B4513),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const Spacer(),
          if (_selectedCategory != null)
            GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = null);
                _loadEntries();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B4513),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedCategory!,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.close, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final selected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = selected ? null : cat;
              });
              _loadEntries();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF8B4513)
                    : const Color(0xFF8B4513).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF8B4513).withValues(alpha: 0.3),
                ),
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
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '字',
            style: TextStyle(
              fontSize: 80,
              color: Color(0xFFD2B48C),
              fontWeight: FontWeight.w100,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'まだ外字が登録されていません',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF8B7355),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '「外字を追加」ボタンから\n漢字を撮影・登録してください',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFAA9988),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _onAddPressed,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('外字を追加する'),
          ),
        ],
      ),
    );
  }

  Widget _buildGaijiGrid() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.85,
        ),
        itemCount: _filteredEntries.length,
        itemBuilder: (context, index) {
          final entry = _filteredEntries[index];
          return GaijiCard(
            entry: entry,
            onTap: () => _onEntryTap(entry),
            onDelete: () => _onDeleteEntry(entry),
          );
        },
      ),
    );
  }
}
