import 'package:hive/hive.dart';
import 'app_settings.dart';

/// Hive TypeAdapter for AppSettings
///
/// Uses JSON serialization via AppSettings.fromJson/toJson for flexible
/// schema evolution. New fields added to AppSettings will be handled
/// gracefully through the fromJson method's default value fallbacks.
class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 0;

  @override
  AppSettings read(BinaryReader reader) {
    final json = reader.readMap().cast<String, dynamic>();
    return AppSettings.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer.writeMap(obj.toJson());
  }
}
