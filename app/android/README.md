# Android Setup (Fasto VPN App)

## 1) Firebase

1. Create Android app in Firebase console.
2. Download `google-services.json`.
3. Place it at:
   - `android/app/google-services.json`
4. Ensure package name matches your Android application ID.

## 2) Google Sign-In

- Add SHA-1/SHA-256 fingerprints in Firebase project settings.
- Ensure Google sign-in provider is enabled in Firebase Auth.

## 3) RevenueCat

- Create Android app in RevenueCat.
- Configure product and entitlement IDs to match `.env` values:
  - `REVENUECAT_ENTITLEMENT_ID`
  - `REVENUECAT_OFFERING_ID`
  - `REVENUECAT_PACKAGE_ID`

## 4) AdMob

- Replace test app ID in `android/app/src/main/AndroidManifest.xml`:
  - `com.google.android.gms.ads.APPLICATION_ID`
- Replace banner unit ID in `.env`:
  - `ADMOB_BANNER_UNIT_ID_ANDROID`

## 5) Telegram deep-link support

- Manifest includes `tg://` query visibility and Telegram packages.
- If you use a custom Telegram flavor, add package under `<queries>`.

## 6) Build / Run

```bash
flutter pub get
flutter run
```

## 7) Release checklist

- Use production Firebase config
- Use production RevenueCat key
- Replace all test AdMob IDs
- Verify backend `API_BASE_URL` points to production API
