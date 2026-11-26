import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/gaiji_repository.dart';
import '../models/gaiji_entry.dart';

/// アルバムの状態管理（端末内保存・オフライン完結）
class GaijiProvider extends ChangeNotifier {
  GaijiProvider(this._repository);

  final GaijiRepository _repository;

  List<GaijiEntry> _entries = [];
  String _query = '';
  GaijiCategory? _categoryFilter;
  SortOrder _sortOrder = SortOrder.newest;

  bool _loading = true;
  bool get loading => _loading;

  String get query => _query;
  GaijiCategory? get categoryFilter => _categoryFilter;
  SortOrder get sortOrder => _sortOrder;

  List<GaijiEntry> get all => List.unmodifiable(_entries);

  /// 絞り込み・並び替え済みの一覧
  List<GaijiEntry> get visible {
    var list = _entries.where((e) {
      final catOk = _categoryFilter == null || e.category == _categoryFilter;
      return catOk && e.matches(_query);
    }).toList();

    switch (_sortOrder) {
      case SortOrder.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SortOrder.oldest:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case SortOrder.name:
        list.sort((a, b) => a.name.compareTo(b.name));
      case SortOrder.reading:
        list.sort((a, b) => a.reading.compareTo(b.reading));
    }
    return list;
  }

  int get total => _entries.length;

  Map<GaijiCategory, int> get countsByCategory {
    final map = <GaijiCategory, int>{};
    for (final c in GaijiCategory.values) {
      map[c] = _entries.where((e) => e.category == c).length;
    }
    return map;
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _entries = _repository.loadAll();
    _loading = false;
    notifyListeners();
  }

  void search(String q) {
    _query = q;
    notifyListeners();
  }

  void filterCategory(GaijiCategory? c) {
    _categoryFilter = c;
    notifyListeners();
  }

  void setSortOrder(SortOrder order) {
    _sortOrder = order;
    notifyListeners();
  }

  Future<void> add({
    required String name,
    required String reading,
    required GaijiCategory category,
    required String source,
    required String memo,
    required Uint8List croppedImage,
    Uint8List? originalImage,
  }) async {
    final entry = GaijiEntry(
      id: 'g_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      reading: reading,
      category: category,
      source: source,
      memo: memo,
      imageBase64: base64Encode(croppedImage),
      originalBase64:
          originalImage == null ? null : base64Encode(originalImage),
      createdAt: DateTime.now(),
    );
    await _repository.save(entry);
    _entries = _repository.loadAll();
    notifyListeners();
  }

  Future<void> update(GaijiEntry entry) async {
    await _repository.save(entry);
    _entries = _repository.loadAll();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    await _repository.delete(id);
    _entries = _repository.loadAll();
    notifyListeners();
  }

  Future<GaijiEntry?> findById(String id) async {
    try {
      return _entries.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}

enum SortOrder {
  newest('新しい順'),
  oldest('古い順'),
  name('名称順'),
  reading('読み順');

  const SortOrder(this.label);
  final String label;
}
