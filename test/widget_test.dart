import 'package:flutter_test/flutter_test.dart';

import 'package:gaiji_album/models/gaiji_entry.dart';

void main() {
  test('GaijiEntry は Map へ往復変換できる', () {
    final entry = GaijiEntry(
      id: 'g_1',
      name: '觀',
      reading: 'かん',
      category: GaijiCategory.itaiji,
      source: '大正蔵',
      memo: '観の旧字',
      imageBase64: 'AAA',
      createdAt: DateTime(2026, 1, 18),
    );
    final restored = GaijiEntry.fromMap(entry.toMap());
    expect(restored.name, '觀');
    expect(restored.reading, 'かん');
    expect(restored.category, GaijiCategory.itaiji);
    expect(restored.createdAt.year, 2026);
  });

  test('検索は名称・読み・メモに一致する', () {
    final entry = GaijiEntry(
      id: 'g_2',
      name: '菩提',
      reading: 'ぼだい',
      memo: '法話で使う',
      imageBase64: 'AAA',
      createdAt: DateTime(2026, 1, 18),
    );
    expect(entry.matches('ぼだい'), isTrue);
    expect(entry.matches('法話'), isTrue);
    expect(entry.matches('存在しない'), isFalse);
  });

  test('不正な分類名はその他にフォールバックする', () {
    expect(GaijiCategory.fromName('unknown'), GaijiCategory.sonota);
    expect(GaijiCategory.fromName(null), GaijiCategory.sonota);
  });
}
