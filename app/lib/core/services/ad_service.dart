import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await MobileAds.instance.initialize();
    _initialized = true;
  }
}
