import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/app_storage.dart';
import 'ad_service.dart';
import 'firebase_auth_service.dart';
import 'firebase_initializer.dart';
import 'revenuecat_service.dart';

final appStorageProvider = Provider<AppStorage>((ref) {
  return AppStorage();
});

final firebaseInitializerProvider = Provider<FirebaseInitializer>((ref) {
  return FirebaseInitializer();
});

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final revenueCatServiceProvider = Provider<RevenueCatService>((ref) {
  return RevenueCatService();
});

final adServiceProvider = Provider<AdService>((ref) {
  return AdService();
});
