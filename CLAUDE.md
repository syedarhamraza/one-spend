# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

One Spend (Dart `package:onespend`, Android application id `com.syedarhamraza.onespend`) is a Flutter subscription/spend tracker styled after Samsung One UI (pitch-black dark theme only). The user-facing name is "One Spend" (two words; `AppInfo.name`); file names use `One-Spend-…`; code identifiers keep `OneSpend`. Android is the only platform directory present. Dart SDK `^3.13.3`.

## Commands

```bash
flutter pub get
flutter run
flutter analyze
flutter test
flutter test test/features/drift_migration_test.dart          # single file
flutter test --plain-name "save and load subscriptions"        # single test by name
dart run build_runner build --delete-conflicting-outputs       # regenerate Drift code (app_database.g.dart)
```

Regenerate with `build_runner` after changing anything under `lib/core/database/tables/` or the `@DriftDatabase` annotation. Bump `schemaVersion` in `app_database.dart` and add a step to its `MigrationStrategy.onUpgrade` when changing table shapes (currently v5: v2 added `reminder_time_minutes`, v3 converted currency symbols to ISO codes, v4 added `logo_transform`, v5 added `annual_plan_price` and the `custom_categories` table). Guard `addColumn` with `_hasColumn` and `createTable` with `_hasTable`, and add an upgrade test (see `test/features/custom_category_test.dart`).

## UI / design language

For any UI work, follow [`docs/design-language.md`](docs/design-language.md): the One UI 8.5 tokens, the component catalog, and the "every option is a subpage with a Cancel | Save pill" recipe. Don't use Material dialogs, pickers or snackbars.

## Architecture

Data and domain logic follow feature-first clean architecture; most UI still lives in the older flat layout.

- **`lib/features/<feature>/{data,domain,presentation}`** — `subscriptions`, `payment_methods`, `settings`, `appearance`. Flow: Drift datasource → `*RepositoryImpl` (maps `*Model` ↔ domain entity) → abstract `*Repository` → controller. Pure logic lives in `subscriptions/domain/services/` (`BillingSchedule` for date advancement and auto-renew, `SubscriptionStats` for totals and sorting) and `subscriptions/data/subscription_exporter.dart`.
- **`lib/screens/`, `lib/widgets/`, `lib/theme/`, `lib/utils/`** — the flat UI layer where almost all screens and `OneUI*` widgets live.
- **`lib/models/subscription.dart`** is a backward-compat barrel that re-exports the feature modules and defines `typedef SubscriptionStore = SubscriptionController`. Screens import this and use `SubscriptionStore.instance`.

### State

- `SubscriptionController` (a `ChangeNotifier`, `lib/features/subscriptions/presentation/controllers/`) is the single app-wide store for subscriptions, payment methods, and user settings. UI rebuilds via `AnimatedBuilder` on it. Computed values are memoized and invalidated in the `notifyListeners` override.
  - **Persistence is granular:** each mutation enqueues only the rows or keys it changed on a serial write queue (`_persist`). Repositories expose `upsert` / `delete` / `replaceAll`, never load-modify-save. `pendingWrites` completes when the queue drains, which is useful in tests.
  - **`load()` is explicit** and awaited in `configureDependencies()` before `runApp`. It always replaces in-memory state, so a fresh install starts empty. The demo catalog is only seeded by `resetForTesting()` or the Settings "restore default catalog" action.
- `OneUIEffectsController` (`lib/features/appearance/presentation/`, re-exported from `lib/theme/one_ui_theme.dart`) is a second singleton for card studio and 3D effects preferences. It persists through `SettingsRepository` (`app_settings` rows prefixed `appearance.`), and becomes a no-op when DI isn't set up. `init()` loads it.

### DI and startup

`lib/core/di/injection.dart` uses GetIt (`sl`). `main()` calls `configureDependencies()`, which:
1. Registers `SharedPreferences` and `AppDatabase`.
2. Runs `SharedPreferencesMigrator`. This is a one-time copy of legacy prefs into Drift: domain data gated by `drift_migrated_v1`, appearance keys gated by `appearance_migrated_v1`.
3. Calls `setupDependencies()`.
4. Awaits the controller `load()` and the effects `init()`.

### Persistence

Drift SQLite (`lib/core/database/`): tables for subscriptions, payment methods, and a key/value `app_settings` table (`getSetting` / `setSetting` / `getSettingsWithPrefix`). Setting keys are the legacy `onespend_*` names, kept for migration compatibility. List fields are stored as JSON via `converters/`.

### Backups (`lib/features/backup/`)

- **Backup file:** `BackupCodec` handles the JSON (`onespend.backup`, format v2; v1 and the legacy bare-list export still restore). Users save it through the system file picker and restore it with `RestorePreviewScreen`, choosing "Add missing items" (`BackupMerge`) or "Replace everything". Bump `BackupCodec.currentVersion` when the file gains data, and keep decoding older versions.
- **Restore points:** `BackupService.saveRestorePoint(reason:)` writes a full snapshot to app storage (`restore_points/restore-<micros>-<reason>.json`, newest 5 kept) before every Replace or Clear all.
  - `undoLast()` is the inline Undo.
  - `listRestorePoints()` feeds Settings › Backup & data › Restore points. Opening a point reuses `RestorePreviewScreen` (`openPoint`), and replacing from a point saves a new point first.
- **Android Auto Backup is off** (`allowBackup=false`, `data_extraction_rules.xml`). Exports (PDF, CSV, text, `.ics`) are not backups.

### Navigation

go_router, configured in `lib/core/router/app_router.dart`:
- **Shell:** `createAppRouter()` builds a `StatefulShellRoute.indexedStack` with four tabs (`/subscriptions`, `/upcoming`, `/analytics`, `/settings`). `HomeScreen` is the shell scaffold. It owns the floating nav bar and a `PopScope` that sends system back to the first tab.
- **Nav bar hiding:** tab-level flags that hide the nav bar live in `HomeChrome` notifiers.
- **Page routes:** `buildPageRoutes()` defines full-screen pages pushed above the shell. Subscription pages are addressed by id (`AppRoutes.subscriptionDetail(id)`, `/history`, `/schedule`) and show a not-found fallback for stale ids. Picker initial values travel via `extra`, using the typedef records in `app_router.dart`.
- **Navigating from screens:** screens call their existing static helpers (`CategoryPickerScreen.open(...)` etc.), which wrap `context.push<T>(...)`. Results come back through `Navigator.pop(context, value)`.
- **Left pageless:** private in-file sub-pages (icon picker sub-screens, payment method field editors, card-studio option screens, `OneUIFieldEditorScreen`) still use `Navigator.push`.
- **Router ownership:** `OneSpendApp` creates its own router in state, so each instance (and each test) starts fresh.

### Pricing

The app is fully free; there is no paywall or entitlement. The earlier OneSpend Pro (Play Billing) implementation was removed and can be revived from commit `3cb0a10` in `main`'s history (`git checkout -b feat/pro 3cb0a10`).

### Telemetry (`lib/core/telemetry/`)

- **Firebase Crashlytics and Analytics, always on in release builds.**
  - Debug builds send nothing unless built with `--dart-define=TELEMETRY_IN_DEBUG=true`.
  - The Advertising ID and ad-services permissions are removed in `AndroidManifest.xml`.
- **Report only through `AppLog`:**
  - `info` is a breadcrumb.
  - `error` is a non-fatal report with a fixed `reason`.
  - `fatal` is used by the uncaught-error handlers in `main.dart`.
  - `event` takes a `TelemetryEvent`; `context` sets crash keys.
  - Don't add `debugPrint('OneSpend: …')` for failures.
- **Never send user content.** No subscription names, prices, notes, URLs or card digits.
  - Events are defined only in `events.dart`, and their params are fixed strings, ints or bools.
  - Custom categories are reported as `custom`.
  - List sizes go through `TelemetryContext.bucket`.
- **Which implementation runs:**
  - `configureDependencies()` starts Firebase first and registers `FirebaseTelemetry`.
  - Firebase reads its settings from `android/app/google-services.json` (project `one-spend`). If that file is missing, the app falls back to `NoopTelemetry`.
  - `setupDependencies()` always registers `NoopTelemetry`, so tests never touch Firebase. To assert on reports, swap in a recording fake (see `test/features/telemetry_test.dart`).
- **Screen views** are the go_router route *pattern* (`/subscriptions/:id`), reported from `OneSpendApp`.

### App updates (`lib/features/updates/`)

- **Play In-App Updates, immediate flow** (`in_app_update`).
  - `PlayUpdateService` talks to Play. It reports `notFromPlay` for `flutter run` or sideloaded builds (Play error -10), and `failed` when Play can't be reached.
  - `setupDependencies()` registers `NoopUpdateService` unless `configureDependencies()` registered Play, so tests never touch the plugin.
- **`UpdateController.instance`** holds the status shown by About › "Check for updates" and the orange `OneUIDot` on Settings › About One Spend.
- **Launch check:** `OneSpendApp` calls `check()` once per launch after the first frame, because Play needs a foreground activity. It never shows a pop-up.
- **Testing a real update:** this only works on a Play-installed build. Use Internal app sharing or an internal-test track with a higher versionCode.

### Versioning and releases

- `version:` in `pubspec.yaml` is the only source: `MAJOR.MINOR.PATCH[-alpha.N|-beta.N]+CODE`. CODE is the Android versionCode, +1 per Play upload.
- `tool/release.ps1` bumps it, adds or stamps the `Changelog` entry, builds the bundle, commits `chore(release): …` and tags `v<name>`. Don't hand-edit the version.
- `AppVersion` (`lib/core/config/app_version.dart`) parses and labels it ("1.0.0 Beta 2"). About and What's new use it.
- `test/features/app_version_test.dart` fails when the pubspec name and `Changelog.entries.first.version` differ.
- Release signing reads `android/key.properties` (git-ignored) and falls back to the debug key.

### Categories

`SubscriptionCategory` is a class, not an enum. The 10 built-ins are `static const` instances with the old enum names, and the stored id is `name`. User-made categories (`CustomCategory`, ids `c_…`) live in the `custom_categories` table and in the static `CustomCategoryRegistry`. `SubscriptionController.load()` fills the registry before it loads subscriptions.
- Instances are canonical (`SubscriptionCategory.custom(id)` returns a cached instance), so identity equality works for map keys and `const` maps. Don't override `==`.
- Use `SubscriptionCategory.all` for pickers and filters. `values` lists only the built-ins.
- `label`, `icon` and `color` resolve custom categories through the registry. A deleted one reads "Other". Custom icons must come from `supportedSubscriptionIcons`, which keeps icon tree-shaking safe.
- Backups are format version 2 and carry `customCategories`. Version 1 backups still restore.


Local notifications only, with no push server. They live in `lib/features/notifications/`:
- **`NotificationPlanner`:** pure logic that turns the current data into a list of `PlannedNotification`s: renewals, card expiry and over-budget alerts. It covers a rolling 60-day window, capped at 50.
- **`NotificationScheduler`:** listens to `SubscriptionController` (debounced) and to app resume. Each time, it cancels what it last scheduled and schedules the new plan. Ids ≤ `PlannedNotification.maxReservedId` belong to the debug-only developer tests in Settings and are never cancelled.
- **Services:**
  - `LocalNotificationService` wraps `flutter_local_notifications` and `flutter_timezone`, uses inexact alarms, and has one Android channel per kind.
  - `setupDependencies()` registers `NoopNotificationService` instead, so tests never touch the plugin.
- **Deep links:** the payload is a go_router location. `OneSpendApp` opens it from the cold-start `launchRoute()` and from live `taps`.
- **Reminder timing:**
  - Per subscription: `reminderDays` and `reminderTimeMinutes`. The time is `null` when the subscription follows the global default; that column was added in schema v2.
  - Globals: `notificationsEnabled` and `defaultReminderTimeMinutes` in `SettingsRepository`.
- **Android setup:** `AndroidManifest.xml` has the POST_NOTIFICATIONS and boot permissions plus the plugin receivers. Core library desugaring is enabled in `android/app/build.gradle.kts`.

## Website

The landing page is a separate public repo, `syedarhamraza/syedarhamraza.github.io` (served at https://syedarhamraza.github.io). It keeps copies of the store captures, the `store/play/` icon and feature graphic, and `docs/privacy-policy.md`. When any of those change here, remind the user to run `npm run sync -- ../one-spend` in the site repo.

## Testing

Tests that touch the controller or DB must inject an in-memory database first:

```dart
setupDependencies(database: AppDatabase.forTesting(NativeDatabase.memory()));
```

- **Fresh state per test:** passing `database:` unregisters and re-registers the datasources, repositories, and controller. Call `SubscriptionStore.instance.resetForTesting()` to seed the demo subscriptions and cards.
- **Datasource tests:** construct `AppDatabase.forTesting(NativeDatabase.memory())` directly and close it in `tearDown` (see `test/features/drift_migration_test.dart`).
- **Reload tests:** build a second controller on the same DB and `await load()` after `await controller.pendingWrites` (see `test/features/persistence_regression_test.dart`).
- **Navigation:** a widget test that navigates via `context.push` (any `*.open(...)` helper) must host the widget with `routedTestApp(widget)` from `test/helpers/test_app.dart` instead of `MaterialApp(home: ...)`.
