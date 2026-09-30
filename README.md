# OneSpend

**A subscription and spend tracker for Android, styled after Samsung One UI 8.5.**

OneSpend keeps track of your recurring payments: what you pay, when it renews, which card it's charged to, and how it adds up against your monthly budget. It works entirely offline on a pitch-black OLED theme with reachable floating controls.

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-%5E3.13.3-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/platform-Android-3DDC84?logo=android&logoColor=white)
![Storage](https://img.shields.io/badge/storage-offline%20SQLite-lightgrey)

---

## Table of contents

- [Features](#features)
- [Tech stack](#tech-stack)
- [Getting started](#getting-started)
- [Development](#development)
- [Project structure](#project-structure)
- [Architecture](#architecture)
- [Database and migrations](#database-and-migrations)
- [Testing](#testing)
- [Design language](#design-language)
- [Contributing](#contributing)
- [Privacy](#privacy)
- [Known limitations](#known-limitations)

---

## Features

### Subscriptions
- Add subscriptions from a catalog of popular services with bundled brand logos, or build your own with a custom icon.
- Categories, flexible billing cycles, start dates and linked payment methods.
- Customize each subscription's card and detail page.
- Search, sort and filter the list.
- Multi-select mode: duplicate, move to a category, or export the selection as CSV.

### Upcoming
- Timeline and calendar views of upcoming renewals.
- Groups for overdue, due this week, due this month and later.
- Mark a charge as paid (with confirmation) and browse recorded payment history.
- Long-press selection mode for bulk actions.

### Analytics
- Spending by category, billing-cycle commitments and forecasts.
- Annual-plan savings, top single expense and smart insights.

### Budget
- Monthly budget threshold with a budget card and over-budget alerts.

### Payment methods
- Manage cards and other payment methods with brand icons and expiry dates.
- See which subscriptions each card pays for.

### Notifications
- Local reminders for upcoming renewals, expiring cards and budget overruns.
- Reminder days and time can be set per subscription, or follow a global default.
- Tapping a notification deep-links to the relevant screen.

### Data
- Everything is stored on-device in SQLite (Drift).
- Export a JSON backup, export CSV, or export renewals to a calendar (`.ics`).
- Restore the sample catalog, or clear all data.

### Appearance
- Card studio: price format, cycle progress bar and metadata chips.
- Detail page styling: icon visibility, icon shape and highlight colour.
- Toggles for 3D depth on the nav bar, floating pills and cards, plus a bottom vignette.

---

## Tech stack

| Concern | Package |
|---|---|
| UI framework | [Flutter](https://flutter.dev) (Dart `^3.13.3`) |
| Navigation | [`go_router`](https://pub.dev/packages/go_router): `StatefulShellRoute` with 4 tabs |
| Persistence | [`drift`](https://pub.dev/packages/drift), `drift_flutter`, `sqlite3_flutter_libs` |
| Dependency injection | [`get_it`](https://pub.dev/packages/get_it) |
| State | `ChangeNotifier` singletons plus `AnimatedBuilder` |
| Notifications | [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications), `timezone`, `flutter_timezone` |
| Sharing and links | `share_plus`, `url_launcher` |
| Assets | `flutter_svg` |
| Formatting | `intl` |
| Legacy migration | `shared_preferences` (one-time import into Drift) |
| Codegen | `build_runner`, `drift_dev` |
| Linting | `flutter_lints` |

---

## Getting started

### Prerequisites

- Flutter SDK with Dart **3.13.3 or newer** (`flutter --version`).
- Android SDK and either an emulator or a device with USB debugging enabled.
- A JDK compatible with your Android Gradle Plugin. Android Studio's bundled JBR works.

Check your setup with:

```bash
flutter doctor
```

### Run the app

```bash
git clone https://github.com/syedarhamraza/one-spend.git
cd one-spend
flutter pub get
flutter run
```

A fresh install starts empty. To load the demo catalog, go to **Settings → Restore sample subscriptions**.

### Release builds

```bash
flutter build apk --release
```

```bash
flutter build appbundle --release
```

The application id is `com.onespend.onespend`. Before publishing to the Play Store, set up a release signing config in `android/app/build.gradle.kts`, which currently falls back to debug signing. Set the version in `pubspec.yaml` (`version: 1.0.0+1`, where the part after `+` is the Android `versionCode`).

---

## Development

| Task | Command |
|---|---|
| Install dependencies | `flutter pub get` |
| Static analysis | `flutter analyze` |
| Run all tests | `flutter test` |
| Run a single test file | `flutter test test/features/drift_migration_test.dart` |
| Run a single test by name | `flutter test --plain-name "save and load subscriptions"` |
| Regenerate Drift code | `dart run build_runner build --delete-conflicting-outputs` |

Regenerate Drift code whenever you change anything under `lib/core/database/tables/` or the `@DriftDatabase` annotation. The generated `app_database.g.dart` is checked in.

---

## Project structure

```text
lib/
├── main.dart                  # Entry point: configureDependencies() → runApp
├── core/
│   ├── database/              # Drift AppDatabase, tables, JSON converters, prefs migrator
│   ├── di/                    # GetIt service locator (injection.dart)
│   ├── error/
│   └── router/                # go_router config, AppRoutes, shell + page routes
├── features/                  # Feature-first clean architecture
│   ├── subscriptions/         # data / domain (BillingSchedule, SubscriptionStats) / presentation
│   ├── payment_methods/
│   ├── settings/
│   ├── appearance/            # OneUIEffectsController (card studio, 3D effects)
│   └── notifications/         # NotificationPlanner, NotificationScheduler, services
├── models/subscription.dart   # Backward-compat barrel + SubscriptionStore typedef
├── screens/                   # Screens (flat UI layer)
├── widgets/                   # OneUI* component library
├── theme/                     # OneUITheme tokens and dynamic getters
└── utils/
assets/logos/                  # Brand and payment-network logos (SVG/PNG)
docs/design-language.md        # UI source of truth
test/
├── features/                  # Domain, persistence, router and notification tests
├── widgets/                   # Widget tests for screens and components
└── helpers/test_app.dart      # routedTestApp() for tests that navigate
```

---

## Architecture

The data and domain layers follow **feature-first clean architecture**. Most UI still lives in the older flat `screens/` and `widgets/` layer.

```mermaid
flowchart LR
    DB[(Drift / SQLite)] --> DS[Drift datasource]
    DS --> RI[RepositoryImpl<br/>Model ↔ Entity]
    RI --> R[Repository<br/>abstract]
    R --> C[SubscriptionController<br/>ChangeNotifier]
    C --> UI[Screens via<br/>AnimatedBuilder]
    C --> NS[NotificationScheduler]
    NS --> NP[NotificationPlanner] --> LN[Local notifications]
```

### State

- **`SubscriptionController`** (exposed to screens as `SubscriptionStore.instance`) is the single app-wide store for subscriptions, payment methods and user settings. Computed values are memoized and invalidated whenever the controller notifies listeners.
- **Granular persistence.** Each mutation queues only the rows or keys it changed on a serial write queue. Repositories expose `upsert`, `delete` and `replaceAll`; nothing loads, modifies and saves. `pendingWrites` completes when the queue is empty.
- **`OneUIEffectsController`** stores appearance preferences as `app_settings` rows prefixed with `appearance.`.

### Startup

`configureDependencies()` in `lib/core/di/injection.dart` runs before `runApp`:

1. Registers `SharedPreferences` and `AppDatabase`.
2. Runs `SharedPreferencesMigrator`, a one-time import of legacy prefs into Drift. It is gated by the `drift_migrated_v1` and `appearance_migrated_v1` flags.
3. Registers datasources, repositories and controllers.
4. Awaits the controller's `load()` and the effects controller's `init()`.

### Navigation

- `createAppRouter()` builds a `StatefulShellRoute.indexedStack` with four tabs: **Subscriptions**, **Upcoming**, **Analytics** and **Settings**. `HomeScreen` is the shell and owns the floating nav bar.
- Full-screen pages are defined in `buildPageRoutes()`. Subscription pages are addressed by id (for example `AppRoutes.subscriptionDetail(id)`) and show a not-found fallback when the id no longer exists.
- Screens navigate through static helpers such as `CategoryPickerScreen.open(...)`, which wrap `context.push<T>`.

### Notifications

Notifications are local only; there is no push server.

- **`NotificationPlanner`** is pure logic. It turns the current data into a plan of renewal, card-expiry and over-budget alerts covering a rolling **60-day window**, capped at **50** notifications.
- **`NotificationScheduler`** re-plans (debounced) whenever the controller changes and whenever the app resumes. Each time, it cancels the previous plan before scheduling the new one.
- **Deep links:** each notification's payload is a go_router location, so tapping one opens the matching screen, including on cold start.

---

## Database and migrations

- Drift database at `lib/core/database/app_database.dart`, currently at **schema version 2**. Version 2 added the per-subscription `reminderTimeMinutes` column.
- Tables: subscriptions, payment methods, and a key/value `app_settings` table.
- List fields are stored as JSON through the type converters in `lib/core/database/converters/`.
- Settings keys keep their legacy `onespend_*` names so older installs still migrate correctly.

**To change the schema:**

1. Edit the table under `lib/core/database/tables/`.
2. Run `dart run build_runner build --delete-conflicting-outputs`.
3. Bump `schemaVersion` and add an `onUpgrade` step to the `MigrationStrategy`.
4. Add or extend a migration test (see `test/features/drift_migration_test.dart`).

---

## Testing

Any test that touches the controller or database must inject an in-memory database first:

```dart
setupDependencies(database: AppDatabase.forTesting(NativeDatabase.memory()));
SubscriptionStore.instance.resetForTesting(); // optional: seed demo data
```

- Passing `database:` re-registers the datasources, repositories and controller, so each test starts with fresh state.
- `setupDependencies()` registers `NoopNotificationService`, so tests never call the notifications plugin.
- **Reload tests:** `await controller.pendingWrites`, then build a second controller on the same database and `await load()` (see `test/features/persistence_regression_test.dart`).
- **Navigation tests:** any widget that calls `context.push` must be hosted with `routedTestApp(widget)` from `test/helpers/test_app.dart`, not `MaterialApp(home: ...)`.

---

## Design language

All UI follows [`docs/design-language.md`](docs/design-language.md), which covers the One UI 8.5 tokens, the component catalog and the interaction patterns. The key rules:

- Every screen sits on true black (`surfacePitch`), with content in soft, rounded charcoal cards.
- **Every option is a subpage** with a back button and a floating **Cancel | Save** pill.
- **No Material dialogs, date/time pickers or snackbars.** Use the `OneUI*` equivalents in `lib/widgets/`.
- Get card and floating colours, borders and shadows from `OneUITheme`'s dynamic getters, because users can turn 3D effects on and off.
- Every interaction triggers haptic feedback.

---

## Contributing

1. Create a branch from `main` (`feat/<topic>` or `fix/<topic>`).
2. Use [Conventional Commits](https://www.conventionalcommits.org/) with a scope, for example `feat(upcoming): …` or `fix(detail): …`.
3. Before opening a pull request:
   - `flutter analyze` reports no issues.
   - `flutter test` passes, and new behaviour has tests.
   - Drift code is regenerated if tables changed, and `schemaVersion` is bumped with a migration.
   - UI changes follow the [design language](docs/design-language.md). Check layouts on a 360dp-wide screen and at large font sizes.
4. Open a pull request against `main` with a short description and screenshots for UI changes.

---

## Privacy

OneSpend has no accounts, analytics, network sync or push server. All data, including subscriptions, payment method details and settings, stays in the app's local SQLite database. For cards, only the last 4 digits are stored. Data leaves the device only when you choose to share an export.

---

## Known limitations

- **Android only.** The repo has no iOS, web or desktop platform directories.
- **Dark theme only**, by design.
- The UI layer is partly migrated. Data and domain logic use feature folders, but most screens still live in `lib/screens/`.
