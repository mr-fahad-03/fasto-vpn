# iOS Setup (Fasto VPN App)

## 1) Firebase

1. Create iOS app in Firebase console.
2. Download `GoogleService-Info.plist`.
3. Add it to Runner target in Xcode:
   - `ios/Runner/GoogleService-Info.plist`

## 2) Google Sign-In

- Enable Google provider in Firebase Auth.
- Add URL scheme from `GoogleService-Info.plist` into iOS URL Types (Runner target).

## 3) RevenueCat

- Create iOS app in RevenueCat.
- Configure products/offerings and match `.env` values:
  - `REVENUECAT_ENTITLEMENT_ID`
  - `REVENUECAT_OFFERING_ID`
  - `REVENUECAT_PACKAGE_ID`

## 4) AdMob

- `ios/Runner/Info.plist` currently includes Google test app ID.
- Replace `GADApplicationIdentifier` with your production AdMob app ID.
- Replace banner unit ID in `.env`:
  - `ADMOB_BANNER_UNIT_ID_IOS`

## 5) Telegram deep-link support

- `LSApplicationQueriesSchemes` includes `tg`, enabling Telegram app availability checks.

## 6) CocoaPods and run

```bash
cd ios
pod install
cd ..
flutter pub get
flutter run
```

## 7) Release checklist

- Production Firebase plist added
- Production RevenueCat key in `.env`
- Production AdMob IDs configured
- Correct backend URL in `API_BASE_URL`
