# Fasto VPN Mobile App (`app`)

Production-ready Flutter client for Fasto VPN (MTProxy browser) with:
- Riverpod state management
- Dio networking
- Firebase Google sign-in + guest mode
- RevenueCat purchase/restore flow
- AdMob banner gating (free users only)
- Session persistence via `shared_preferences`

## Features

- Entry flow: splash -> onboarding -> auth choice (guest / Google)
- Session restore on relaunch
- Backend entitlement as source of truth for premium unlocks
- Proxy list with search/filter, country flag/name, free/premium visibility
- Proxy detail with copy/share and Telegram deep-link helper
- Premium paywall (`US$9.99/month` target), restore purchases
- Profile, settings, and subscription status screens

## Folder Overview

```text
lib/
  core/
    config/
    constants/
    models/
    networking/
    routing/
    services/
    storage/
    theme/
    widgets/
  features/
    bootstrap/
    onboarding/
    auth/
    home/
    proxies/
    subscription/
    profile/
    settings/
```

## Environment

Copy `.env.example` to `.env` and fill values:

```bash
cp .env.example .env
```

Required keys:
- `API_BASE_URL`
- `FIREBASE_ENABLED`
- `REVENUECAT_API_KEY_ANDROID`
- `REVENUECAT_API_KEY_IOS`
- `REVENUECAT_ENTITLEMENT_ID`
- `REVENUECAT_OFFERING_ID`
- `REVENUECAT_PACKAGE_ID`
- `ADMOB_APP_ID_ANDROID`
- `ADMOB_APP_ID_IOS`
- `ADMOB_BANNER_UNIT_ID_ANDROID`
- `ADMOB_BANNER_UNIT_ID_IOS`

## Backend API Contract Used

- `POST /mobile/sessions/guest`
- `GET /mobile/proxies`
- `GET /mobile/entitlement`

Auth headers:
- Google mode: `Authorization: Bearer <firebase_id_token>`
- Guest mode: `x-guest-session-id: <session_id>`

## Run

```bash
flutter pub get
flutter run
```

## Validate

```bash
flutter analyze
flutter test
```

## Platform Setup

- Android setup notes: `android/README.md`
- iOS setup notes: `ios/README.md`

## Notes

- RevenueCat is initialized at app bootstrap.
- Ads render only when backend entitlement is free and ads-enabled.
- Premium purchase for guest sessions is blocked by design; user must sign in with Google.
