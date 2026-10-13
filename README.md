# KaSpot

**Stay connected. Wherever life takes you.**

KaSpot is an Android-first, privacy-led location-sharing Flutter application built for families, couples, and close circles of trust. Engineered around explicit consent, zero historical location trails, and battery-smart background tracking.

---

## Key Highlights & Features

### 📍 True Zero-Trail Privacy
* **Single-Coordinate Architecture**: KaSpot never saves your movement history, route logs, or past breadcrumbs. Only your single latest coordinate is preserved via atomic `UPSERT`.
* **Explicit, Per-Person Consent**: Connecting with someone does not automatically share your location. Each sharing grant is a separate, mutual choice that can be toggled on or revoked instantly.

### 🔋 Battery-Smart Background Location Tracking
* **Consent-First**: Disabled by default. Toggled explicitly by the user in Privacy Controls or via the Map quick-actions sheet.
* **Smart Movement Throttling**: Utilizes a 50-meter distance filter and 30-second interval throttling so the device sleeps while stationary, minimizing battery consumption and network egress.
* **Android 14+ Compliant**: Runs as an Android foreground service with a persistent status notification (*"KaSpot · Live Sharing Active"*) to ensure complete user transparency.
* **Partner Map Awareness**: When background tracking is disabled and the app is closed, loved ones' pins clearly display *"App inactive · Last seen Xm ago"*.

### 🗺️ Precision Map Experience
* **Radial Heartbeat Beacon**: Perfectly centered map marker with an organic slow heartbeat pulsing animation, display name tag, and profile picture avatar.
* **No Coordinate Drift**: Mathematical center-alignment ensures zero pixel drift across all zoom levels.
* **Stable, North-Locked Map**: Calm, predictable gestures — the map never twists away from north or glides off-course — plus switchable Standard (OpenStreetMap) and Satellite (Esri World Imagery) layers.

### 🖼️ Smart Profile Picture Compression
* Client-side optimization downscales images and applies high-efficiency compression, shrinking multi-megabyte photos to 15KB–35KB avatars before upload to conserve cloud storage and network bandwidth.

### ✨ Polished Mobile Interface
* **Floating Interactive Navigation Bar**: Dynamic pill-style bottom navigation with smooth sliding active indicator and haptic-feel micro-interactions.
* **SVG Vector Brand Identity**: Bespoke typography with custom location-pin motif.

---

## Tech Stack

* **Framework**: Flutter (Dart 3.x)
* **Maps**: `flutter_map` with OpenStreetMap
* **Location Engine**: `geolocator` with foreground service configuration
* **Backend / Database**: Supabase (PostgreSQL with Row-Level Security and Realtime engine)
* **Images**: `image_picker` + `image` package optimizer

---

## Project Structure

```
lib/
├── main.dart                          # App entry point & background service initialization
├── screens/
│   ├── auth_screen.dart               # Email/Password authentication & onboarding
│   ├── home_shell.dart                # Main container with interactive floating nav bar
│   ├── map_screen.dart                # Real-time map, pulsing beacon & partner status chips
│   ├── connections_screen.dart        # Circle management & consent-based sharing grants
│   ├── places_screen.dart             # Favorite/saved locations
│   └── profile_screen.dart            # Profile, avatar upload, and Privacy & Controls
├── services/
│   ├── background_location_service.dart # Foreground service & battery-smart GPS stream
│   └── kaspot_service.dart            # Supabase API client, RLS queries & state notifiers
├── utils/
│   └── image_optimizer.dart           # Client-side 15KB-35KB image compression
└── widgets/
    ├── interactive_nav_bar.dart       # Floating pop-out navigation bar
    ├── kaspot_avatar.dart             # Avatar widget with fallback initials
    └── kaspot_logo.dart               # Official KaSpot vector logo & brand colors
```

---

## Local Development & Setup

### Prerequisites
* Flutter SDK (3.24+ recommended)
* Android SDK / Android Studio (with API 34+ build tools)

### 1. Clone the repository
```sh
git clone https://github.com/Shermanjk/ka-spot.git
cd ka-spot
```

### 2. Install dependencies & verify code
```sh
flutter pub get
flutter analyze
```

### 3. Run the application
To connect your Supabase project (recommended):
1. Copy the template:
   ```sh
   cp .env.example .env
   ```
2. Fill in your `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `.env`.
3. Run the app:
   ```sh
   flutter run
   ```

Alternatively, you can provide environment variables via CLI flags:
```sh
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

### 4. Build Debug APK
```sh
flutter build apk --debug
```
The APK output will be located at `build/app/outputs/flutter-apk/app-debug.apk`.

---

## Database Setup (Supabase)

If setting up your own Supabase backend:
1. Create a new Supabase project at [supabase.com](https://supabase.com).
2. Open the **SQL Editor** in the Supabase dashboard.
3. Paste and run the contents of [`supabase/schema.sql`](supabase/schema.sql) — safe to re-run at any time: it upgrades an existing project in place (tables, policies, triggers and grants are all idempotent).
4. In **Database > Replication**, add `locations` and `location_sharing` to the `supabase_realtime` publication to enable live map updates.

---

## Authentication Configuration (Supabase & Google — Manual Steps)

The client enforces the authentication policy defensively, but the following project-side settings are **required** for the intended behavior. They cannot be configured from this repository:

1. **Supabase → Authentication → Email**: enable **"Confirm email"**. Without it, `signUp` immediately returns an active session for any syntactically valid address, and unverified (or nonexistent) mailboxes gain access with no confirmation step.
2. **Supabase → Authentication → URL Configuration**: add `io.supabase.kaspot://login-callback` to the **Redirect URLs** list so email-confirmation and password-recovery links return to the app (the deep link is handled automatically by `supabase_flutter` on Android).
3. **Supabase → Authentication → Providers → Google**: enable Google using the Web client ID/secret. The Google **Web** OAuth client must list `https://<project-ref>.supabase.co/auth/v1/callback` as an authorized redirect URI.
4. **Google Cloud Console**: the Android OAuth client must include the package name `com.kaspot.kaspot` and the **SHA-1 fingerprint of the keystore used to sign builds**. `android/app/build.gradle.kts` currently signs release builds with the debug keystore; register that SHA-1 (or the real release keystore's) or Google Sign-In fails with error code 10.
5. Keep `client_secret*.json` files and `Supabase Pass.txt` out of version control (already covered by `.gitignore`) and rotate the Google OAuth client secret if it was ever committed.
6. **Supabase → SQL Editor**: apply the registration-flag migration (one time, existing databases; fresh databases already include the column in `supabase/schema.sql`):

   ```sql
   alter table public.profiles add column if not exists registered_at timestamptz;
   update public.profiles set registered_at = coalesce(created_at, now()) where registered_at is null;
   ```

   With this flag, a Google account can only sign in **after** it has completed a KaSpot registration: the Sign In screen rejects never-registered Google accounts (Supabase would otherwise silently create one) and tells the user to register via **Create Account** first. Existing accounts are backfilled by the `update` above. If the column is missing (migration not applied), the client fails open so a configuration gap can never lock legitimate users out.
7. **Supabase → SQL Editor**: apply the Circle invitation hardening (one time, existing databases; fresh databases already include it in `supabase/schema.sql`):

   ```sql
drop policy if exists requests_participant_transition on public.connection_requests;
create policy requests_participant_transition on public.connection_requests for update to authenticated
using ((requester_id = (select auth.uid()) or recipient_id = (select auth.uid())) and status = 'pending')
with check (
  (requester_id = (select auth.uid()) or recipient_id = (select auth.uid()))
  and (
    (status in ('accepted', 'rejected') and recipient_id = (select auth.uid()))
    or (status = 'cancelled' and requester_id = (select auth.uid()))
  )
);
   ```

   The Circle flow is an invitation: one side sends it with a Circle Code, and only the recipient can accept or decline — the sender can at most cancel. This policy enforces that server-side; without it, a modified client could self-accept its own pending request and bypass consent.

A development-only **local preview session** (fabricated local user, no server verification) can be enabled explicitly with `KASPOT_LOCAL_PREVIEW=true` in `.env` or `--dart-define=KASPOT_LOCAL_PREVIEW=true`. It must never be enabled for release builds; without it, the app refuses to fabricate an authenticated session when Supabase is unreachable or unconfigured.

---

## Security & Architecture Principles

* **Row-Level Security (RLS)**: Location rows are visible only to users with an active, mutual `location_sharing` grant.
* **No Secret Keys in Client**: The client application uses only the public publishable/anon key.
* **Cascade Cleanup**: Deleting an account removes all associated connections, locations, and profile records automatically (`ON DELETE CASCADE`).

---

## License & Repository

Maintained at [github.com/Shermanjk/ka-spot](https://github.com/Shermanjk/ka-spot).
