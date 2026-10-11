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
* **OpenStreetMap Integration**: Clean OSM tile rendering with full attribution.

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
To run in local demo mode (no backend required):
```sh
flutter run
```

To connect to your own Supabase project:
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
3. Paste and run the contents of [`supabase/schema.sql`](supabase/schema.sql).
4. In **Database > Replication**, add `locations` and `location_sharing` to the `supabase_realtime` publication to enable live map updates.

---

## Security & Architecture Principles

* **Row-Level Security (RLS)**: Location rows are visible only to users with an active, mutual `location_sharing` grant.
* **No Secret Keys in Client**: The client application uses only the public publishable/anon key.
* **Cascade Cleanup**: Deleting an account removes all associated connections, locations, and profile records automatically (`ON DELETE CASCADE`).

---

## License & Repository

Maintained at [github.com/Shermanjk/ka-spot](https://github.com/Shermanjk/ka-spot).
