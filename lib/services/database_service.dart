import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/gaiji_entry.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  static const _uuid = Uuid();
  static const _boxName = 'gaiji_entries';

  Box<GaijiEntry> get _box => Hive.box<GaijiEntry>(_boxName);

  // 全件取得（登録日時降順）
  Future<List<GaijiEntry>> getAllEntries() async {
    final entries = _box.values.toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  // カテゴリで絞り込み
  Future<List<GaijiEntry>> getEntriesByCategory(String category) async {
    final entries = _box.values
        .where((e) => e.category == category)
        .toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  // 名前・メモで検索
  Future<List<GaijiEntry>> searchByName(String keyword) async {
    final lower = keyword.toLowerCase();
    final entries = _box.values.where((e) {
      final nameMatch = e.name.toLowerCase().contains(lower);
      final memoMatch = e.memo?.toLowerCase().contains(lower) ?? false;
      return nameMatch || memoMatch;
    }).toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  // 追加
  Future<GaijiEntry> insertEntry(GaijiEntry entry) async {
    final id = _uuid.v4();
    entry.id = id;
    await _box.put(id, entry);
    return entry;
  }

  // 更新
  Future<void> updateEntry(GaijiEntry entry) async {
    if (entry.id == null) return;
    await _box.put(entry.id!, entry);
  }

  // 削除
  Future<void> deleteEntry(String id) async {
    await _box.delete(id);
  }

  // カテゴリ一覧取得
  Future<List<String>> getCategories() async {
    final categories = _box.values
        .where((e) => e.category != null && e.category!.isNotEmpty)
        .map((e) => e.category!)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  // 件数取得
  Future<int> getTotalCount() async {
    return _box.length;
  }
}
