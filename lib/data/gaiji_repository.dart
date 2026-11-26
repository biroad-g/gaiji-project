import 'package:hive_flutter/hive_flutter.dart';

import '../models/gaiji_entry.dart';

/// 端末内（オフライン）保存用リポジトリ。
/// Web では IndexedDB、Android では端末ストレージに保存される。
class GaijiRepository {
  static const _boxName = 'gaiji_entries_v1';

  late Box<dynamic> _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
  }

  Box<dynamic> get box => _box;

  List<GaijiEntry> loadAll() {
    final list = <GaijiEntry>[];
    for (final raw in _box.values) {
      if (raw is Map) {
        try {
          list.add(GaijiEntry.fromMap(raw));
        } catch (_) {
          // 破損レコードは読み飛ばす（アプリが落ちないように）
        }
      }
    }
    return list;
  }

  Future<void> save(GaijiEntry entry) async {
    await _box.put(entry.id, entry.toMap());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> clear() async {
    await _box.clear();
  }

  int get count => _box.length;
}
