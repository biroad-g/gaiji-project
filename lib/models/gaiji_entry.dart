import 'dart:typed_data';
import 'package:hive/hive.dart';

part 'gaiji_entry.g.dart';

@HiveType(typeId: 0)
class GaijiEntry extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String imagePath; // Mobile: ファイルパス / Web: UUID key

  @HiveField(3)
  String? memo;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  String? category;

  @HiveField(6)
  Uint8List? imageBytes; // Web用：画像バイト列

  GaijiEntry({
    this.id,
    required this.name,
    required this.imagePath,
    this.memo,
    required this.createdAt,
    this.category,
    this.imageBytes,
  });

  GaijiEntry copyWith({
    String? id,
    String? name,
    String? imagePath,
    String? memo,
    DateTime? createdAt,
    String? category,
    Uint8List? imageBytes,
  }) {
    return GaijiEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      imageBytes: imageBytes ?? this.imageBytes,
    );
  }
}
