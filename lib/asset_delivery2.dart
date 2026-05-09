import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

class AssetDelivery2 {
  static const MethodChannel _channel = MethodChannel('asset_delivery2');

  // This variable holds the base path to the assets (Cache on Android, Bundle on iOS)
  static String? _basePath;

  /// On Android: This triggers the background extraction of assets to the cache.
  /// Initializes the asset pack and returns its physical local path.
  /// [tag] is the ODR/Play Asset Delivery tag.
  /// [sampleFilename] is the name of ONE file inside the pack (e.g., 'brain_bg.png')
  /// needed by iOS to locate the hidden asset directory.
  static Future<void> initialize(
    String tag, {
    required String sampleFilename,
  }) async {
    try {
      final String? path = await _channel.invokeMethod<String>('initialize', {
        'tag': tag,
        'sampleFilename': "images/$sampleFilename",
      });
      _basePath = path;
    } on PlatformException catch (e) {
      throw Exception("Failed to initialize asset pack '$tag': ${e.message}");
    }
  }

  /// [filename] The relative path to the asset (e.g., "background.png" or "images/hero.png").
  /// Throws an exception if [initialize] has not been called.
  static String getFile(String filename) {
    if (_basePath == null) {
      throw Exception(
        "AssetDelivery2 not initialized! Call initialize() first.",
      );
    }
    final fullPath = Platform.isAndroid
        ? p.join(_basePath!, 'images', filename)
        : p.join(_basePath!, 'images', filename);
    return fullPath;
  }

  /// Helper to check if the file actually exists
  bool exists(String filename) {
    return File(getFile(filename)).existsSync();
  }

  /// Releases the asset pack associated with the [tag], freeing up device storage.
  Future<void> release(String tag) async {
    try {
      await _channel.invokeMethod<bool>('release', {'tag': tag});
    } on PlatformException catch (e) {
      throw Exception("Failed to release asset pack '$tag': ${e.message}");
    }
  }
}
