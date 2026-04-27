import 'package:afriomarkets_cust_app/app_config.dart';

class PathHelper {
  /// Returns a full URL for an image path.
  /// If the path is already an absolute URL (starts with http), it returns it as is.
  /// Otherwise, it prepends AppConfig.BASE_PATH.
  /// Returns null if path is null or empty.
  static String? getImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return null;
    }

    if (path.startsWith('http')) {
      return path;
    }

    return "${AppConfig.BASE_PATH}$path";
  }

  /// Non-null variant. Returns empty string if path is null or empty,
  /// so it can safely be passed to widgets requiring a non-null String.
  static String getImageUrlSafe(String? path) {
    return getImageUrl(path) ?? '';
  }
}
