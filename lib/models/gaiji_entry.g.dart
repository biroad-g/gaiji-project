// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gaiji_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GaijiEntryAdapter extends TypeAdapter<GaijiEntry> {
  @override
  final int typeId = 0;

  @override
  GaijiEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GaijiEntry(
      id: fields[0] as String?,
      name: fields[1] as String,
      imagePath: fields[2] as String,
      memo: fields[3] as String?,
      createdAt: fields[4] as DateTime,
      category: fields[5] as String?,
      imageBytes: fields[6] as dynamic,
    );
  }

  @override
  void write(BinaryWriter writer, GaijiEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.imagePath)
      ..writeByte(3)
      ..write(obj.memo)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.imageBytes);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GaijiEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
