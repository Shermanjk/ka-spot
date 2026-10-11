# KaSpot

**Your people. Your places. Your peace of mind.**

An Android-first Flutter/Dart development foundation for consent-led sharing among trusted people. Map-first, privacy-led, and deliberately without fake live coordinates.

## What's included

- Flutter mobile application, map-first navigation and KaSpot visual identity.
- OpenStreetMap-backed Flutter Map, visible attribution, permission-aware foreground location.
- Connection, saved-place, notification, profile, and privacy/settings surfaces.
- Optional Supabase initialization using public client URL/anon key supplied at run time.
- PostgreSQL schema and RLS policies in `supabase/schema.sql`, including per-recipient sharing consent and a latest-location-only table.
- Local preview when no backend is configured, explicitly labelled as local preview; no simulated location markers.

## Local development

Install Flutter stable and Android Studio/Android SDK on a development computer, accept Android SDK licenses (`flutter doctor --android-licenses`), then run:

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

For a locally installable debug APK, connect an Android SDK-equipped development computer and run `flutter build apk --debug`; then install `build/app/outputs/flutter-apk/app-debug.apk` with `adb install -r build/app/outputs/flutter-apk/app-debug.apk`. Release signing and an actual device test are not included in this source deliverable.

The hosted Sandbox used to author this source may lack Android SDK/emulator/device access; run `flutter doctor` on your Android development machine. To use Supabase, create a project on an eligible Supabase tier, apply `supabase/schema.sql`, and launch with:

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_OR_PUBLISHABLE_KEY
```

The anon/publishable key is not a secret; RLS is the security boundary. **Never put a service-role key in the app, command history, source control, or public builds.** No real backend is configured in this workspace. Authentication, account verification/recovery, policy enforcement, and cross-account RLS must be verified against a project with at least two test accounts before live location sharing is treated as production-ready.

Account-owned rows reference `auth.users` with `ON DELETE CASCADE`, so their profile, connection, sharing, latest-location, place and preference data is removed when the auth account is deleted. This build does not expose an in-app account-deletion button: safe self-service deletion needs a separately reviewed Edge Function or another trusted server path, never a service-role key in the client. Until that is configured, account deletion must be performed through an authorized project-owner workflow.

## Permissions and map tiles

Foreground GPS is consent-gated and does not promise background tracking. Coordinates are uploaded on explicit locate/share actions only; there is no periodic or background polling loop. Test permission denial, approximate location, app restart, offline mode, stale timestamps and battery behavior on actual Android devices. No continuous/background tracking or geofencing is enabled by default. The map uses OpenStreetMap data attribution. The default public tile service is for development/demo use, subject to the tile provider's current usage policy, rate limits and availability; it is not an unlimited production tile backend. Choose a compliant provider before broad deployment and keep attribution visible.

## Supabase and RLS

The schema stores one latest coordinate row per account rather than a location trail. Accepted connection status is created only after a recipient accepts a pending request. Sharing is a separate per-owner/per-recipient grant. The owner writes a location only while at least one sharing grant is enabled; an authorized connected recipient reads only when the grant remains enabled. Pausing/revoking immediately removes the recipient's RLS-visible access, and a database trigger deletes the latest row when the owner's final enabled grant ends. Verify all paths directly using an unrelated account, as well as an allowed account; do not test destructive changes using production user data.

The map subscribes to RLS-visible `public.locations` inserts/updates and `public.location_sharing` changes, then reloads authorized records. Add both tables to the Supabase `supabase_realtime` publication only after reviewing the project's RLS/realtime setup and quotas; manual refresh remains available if Realtime is not enabled. Location deletes are deliberately not subscribed to, because PostgreSQL change-feed deletes cannot be filtered by RLS in the same way; revocation changes on `location_sharing` cause the recipient view to refresh. Realtime does not itself send push notifications. FCM requires a Firebase project, Android app registration, `google-services.json`, Android Gradle plugin configuration, notification permission/channel setup, token lifecycle, and a separately secured notification sender. Those steps are project-specific and are not claimed complete here. Arrival/departure geofencing and background notifications are not implemented in this starter.

## Free tier, availability and costs

This code does not require a paid API or service. Supabase and Firebase free-tier quotas, inactive-project pause rules, notification delivery behavior, data-retention settings and current terms can change; consult each provider's current console and pricing/usage documentation before launch. Free-tier availability is not guaranteed or unlimited. OSM public tiles likewise have capacity and usage rules. No paid service has been added. Avoid high-frequency writes, historical tracks, broad Realtime subscriptions and unnecessary image uploads to conserve quotas and battery.

## Current implementation status

This is a development foundation, not a finished production safety product. No external Supabase or Firebase project credentials, device test account, RLS test report, configured FCM sender, physical-device verification, signed APK or production tile contract is supplied. Review and test authorization, location revocation, account deletion/data retention, background behavior and notification flows before release. The UI must not be taken as evidence that backend integrations are active until a real configured project is connected.

The source is suitable for local Git version control. No GitHub remote has been selected; choose a repository and its privacy/ownership settings before pushing the code to GitHub.
