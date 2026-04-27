import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static const String _defaultApiPrefix = '/api/v1';

  static String get apiBaseUrl {
    final configured = dotenv.env['API_BASE_URL']?.trim() ?? '';
    final fallback = Platform.isAndroid
        ? 'http://10.0.2.2:4000$_defaultApiPrefix'
        : 'http://127.0.0.1:4000$_defaultApiPrefix';
    final raw = configured.isEmpty ? fallback : configured;
    final normalizedHost = _normalizeLoopbackHost(raw);
    return _ensureApiPrefix(normalizedHost);
  }

  static String _normalizeLoopbackHost(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) {
      return url;
    }

    if (Platform.isIOS && uri.host == '10.0.2.2') {
      return uri.replace(host: '127.0.0.1').toString();
    }

    if (Platform.isAndroid && (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
      return uri.replace(host: '10.0.2.2').toString();
    }

    return url;
  }

  static String _ensureApiPrefix(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) {
      return url;
    }

    final rawPath = uri.path.isEmpty ? '/' : uri.path;
    final normalizedPath = rawPath.endsWith('/') && rawPath.length > 1
        ? rawPath.substring(0, rawPath.length - 1)
        : rawPath;

    if (normalizedPath == '/' || normalizedPath == '/api') {
      return uri.replace(path: _defaultApiPrefix).toString();
    }

    return uri.toString();
  }

  static bool get firebaseEnabled =>
      (dotenv.env['FIREBASE_ENABLED'] ?? 'false').toLowerCase() == 'true';

  static String get revenueCatApiKeyAndroid =>
      dotenv.env['REVENUECAT_API_KEY_ANDROID'] ?? '';

  static String get revenueCatApiKeyIos =>
      dotenv.env['REVENUECAT_API_KEY_IOS'] ?? '';

  static String get revenueCatEntitlementId =>
      dotenv.env['REVENUECAT_ENTITLEMENT_ID'] ?? 'premium';

  static String get revenueCatOfferingId =>
      dotenv.env['REVENUECAT_OFFERING_ID'] ?? 'default';

  static String get revenueCatPackageId =>
      dotenv.env['REVENUECAT_PACKAGE_ID'] ?? 'monthly';

  static String get admobAppIdAndroid =>
      dotenv.env['ADMOB_APP_ID_ANDROID'] ??
      'ca-app-pub-3940256099942544~3347511713';

  static String get admobAppIdIos =>
      dotenv.env['ADMOB_APP_ID_IOS'] ??
      'ca-app-pub-3940256099942544~1458002511';

  static String get admobBannerUnitAndroid =>
      dotenv.env['ADMOB_BANNER_UNIT_ID_ANDROID'] ??
      'ca-app-pub-3940256099942544/6300978111';

  static String get admobBannerUnitIos =>
      dotenv.env['ADMOB_BANNER_UNIT_ID_IOS'] ??
      'ca-app-pub-3940256099942544/2934735716';

  static String get revenueCatApiKey {
    if (Platform.isIOS) return revenueCatApiKeyIos;
    return revenueCatApiKeyAndroid;
  }

  static String get bannerUnitId {
    if (Platform.isIOS) return admobBannerUnitIos;
    return admobBannerUnitAndroid;
  }
}
