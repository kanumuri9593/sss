import 'package:hive/hive.dart';
import 'container.dart';

/// Hive Type Adapter for Container
class ContainerAdapter extends TypeAdapter<Container> {
  @override
  final int typeId = 0;

  @override
  Container read(BinaryReader reader) {
    final json = Map<String, dynamic>.from(reader.readMap());
    return Container.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, Container obj) {
    writer.writeMap(obj.toJson());
  }
}
