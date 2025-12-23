import 'package:hive/hive.dart';
import 'app_settings.dart';

/// Hive Adapter for AppSettings
///
/// TypeId 2 (Container=0, Item=1, AppSettings=2)
class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 2;

  @override
  AppSettings read(BinaryReader reader) {
    final json = Map<String, dynamic>.from(reader.readMap());
    return AppSettings.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer.writeMap(obj.toJson());
  }
}
