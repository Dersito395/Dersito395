import 'package:flutter/services.dart';

/// Espaço livre no armazenamento do aparelho, obtido por código nativo
/// (Android: StatFs; iOS: volumeAvailableCapacityForImportantUsage).
class StorageInfo {
  static const MethodChannel _channel = MethodChannel('br.app.sobreviva/storage');

  static Future<int?> freeBytes() async {
    try {
      final v = await _channel.invokeMethod<Object?>('freeBytes');
      return v is int ? v : null;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
