import 'package:hive/hive.dart';
import 'item.dart';

/// Hive Type Adapter for Item
class ItemAdapter extends TypeAdapter<Item> {
  @override
  final int typeId = 1;

  @override
  Item read(BinaryReader reader) {
    final json = Map<String, dynamic>.from(reader.readMap());
    return Item.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, Item obj) {
    writer.writeMap(obj.toJson());
  }
}
