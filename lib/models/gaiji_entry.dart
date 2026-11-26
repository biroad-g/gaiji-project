import 'dart:convert';
import 'dart:typed_data';

/// 外字の分類
enum GaijiCategory {
  itaiji('異体字', '異'),
  koji('古字', '古'),
  bonji('梵字', '梵'),
  inyo('印影', '印'),
  sonota('その他', '他');

  const GaijiCategory(this.label, this.mark);
  final String label;
  final String mark;

  static GaijiCategory fromName(String? name) {
    return GaijiCategory.values.firstWhere(
      (e) => e.name == name,
      orElse: () => GaijiCategory.sonota,
    );
  }
}

/// 外字1件
class GaijiEntry {
  GaijiEntry({
    required this.id,
    required this.name,
    this.reading = '',
    this.category = GaijiCategory.sonota,
    this.source = '',
    this.memo = '',
    required this.imageBase64,
    this.originalBase64,
    required DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;

  /// 外字の名称（例：觀、菩提、𠮷 など）
  final String name;

  /// 読み（かん、ぼだい など）
  final String reading;

  final GaijiCategory category;

  /// 出典（『大正蔵』第12巻、〇〇寺蔵 版木 など）
  final String source;

  /// 自由メモ
  final String memo;

  /// 切り取った字形（透過 PNG / PNG を base64 で保持）
  final String imageBase64;

  /// 撮影した元写真（参照用・任意）
  final String? originalBase64;

  final DateTime createdAt;
  final DateTime? updatedAt;

  Uint8List get imageBytes => base64Decode(imageBase64);

  Uint8List? get originalBytes =>
      originalBase64 == null ? null : base64Decode(originalBase64!);

  GaijiEntry copyWith({
    String? name,
    String? reading,
    GaijiCategory? category,
    String? source,
    String? memo,
    String? imageBase64,
    String? originalBase64,
    DateTime? updatedAt,
  }) {
    return GaijiEntry(
      id: id,
      name: name ?? this.name,
      reading: reading ?? this.reading,
      category: category ?? this.category,
      source: source ?? this.source,
      memo: memo ?? this.memo,
      imageBase64: imageBase64 ?? this.imageBase64,
      originalBase64: originalBase64 ?? this.originalBase64,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'reading': reading,
        'category': category.name,
        'source': source,
        'memo': memo,
        'imageBase64': imageBase64,
        'originalBase64': originalBase64,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  static GaijiEntry fromMap(Map<dynamic, dynamic> map) {
    return GaijiEntry(
      id: (map['id'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      reading: (map['reading'] ?? '') as String? ?? '',
      category: GaijiCategory.fromName(map['category'] as String?),
      source: (map['source'] ?? '') as String? ?? '',
      memo: (map['memo'] ?? '') as String? ?? '',
      imageBase64: (map['imageBase64'] ?? '') as String? ?? '',
      originalBase64: map['originalBase64'] as String?,
      createdAt: DateTime.tryParse((map['createdAt'] ?? '') as String? ?? ''),
      updatedAt: DateTime.tryParse((map['updatedAt'] ?? '') as String? ?? ''),
    );
  }

  /// 検索用に全項目を連結した文字列
  String get searchIndex =>
      '$name $reading ${category.label} $source $memo'.toLowerCase();

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return searchIndex.contains(q);
  }
}
