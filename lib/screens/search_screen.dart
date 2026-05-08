import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/gaiji_entry.dart';
import '../services/database_service.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<GaijiEntry> _results = [];
  bool _hasSearched = false;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String keyword) async {
    if (keyword.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await DatabaseService.instance.searchByName(keyword.trim());
      setState(() {
        _results = results;
        _hasSearched = true;
      });
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _onEntryTap(GaijiEntry entry) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(entry: entry)),
    );
    if (result == true) {
      await _search(_searchController.text);
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5EF),
      appBar: AppBar(title: const Text('外字を検索')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '名前・メモで検索...',
                hintStyle: const TextStyle(color: Color(0xFFAA9988)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF8B4513)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFFAF5EF),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFFD2B48C)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFFD2B48C)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFF8B4513), width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() {});
                _search(value);
              },
              onSubmitted: _search,
            ),
          ),
          Expanded(
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF8B4513)),
                  )
                : !_hasSearched
                    ? _buildInitialState()
                    : _results.isEmpty
                        ? _buildNoResults()
                        : _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64,
            color: const Color(0xFF8B4513).withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            '名前またはメモで検索できます',
            style: TextStyle(color: Color(0xFFAA9988), fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '見つかりません',
            style: TextStyle(fontSize: 18, color: Color(0xFF8B7355), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            '「${_searchController.text}」に一致する外字はありません',
            style: const TextStyle(color: Color(0xFFAA9988), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '${_results.length} 件見つかりました',
            style: const TextStyle(
              color: Color(0xFF8B4513), fontSize: 13, fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: _results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = _results[index];
              return _SearchResultItem(
                entry: entry,
                onTap: () => _onEntryTap(entry),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SearchResultItem extends StatelessWidget {
  final GaijiEntry entry;
  final VoidCallback onTap;

  const _SearchResultItem({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD2B48C).withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF8B4513).withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFFAF5EF),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: _buildThumbnail(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3A2A1A),
                    ),
                  ),
                  if (entry.category != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B4513).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        entry.category!,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF8B4513)),
                      ),
                    ),
                  ],
                  if (entry.memo != null && entry.memo!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.memo!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFAA9988)),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFFD2B48C), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (kIsWeb && entry.imageBytes != null) {
      return Image.memory(entry.imageBytes!, fit: BoxFit.contain);
    }
    if (!kIsWeb && entry.imagePath.isNotEmpty) {
      final file = File(entry.imagePath);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.contain);
      }
    }
    return const Icon(Icons.image, color: Colors.grey);
  }
}
