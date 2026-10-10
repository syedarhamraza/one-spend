# Releasing One Spend

Maintainer guide for versioning, building, signing and shipping to Google Play. For a printable summary, see [`One-Spend-Release-Cheatsheet.pdf`](One-Spend-Release-Cheatsheet.pdf).

- [Versioning](#versioning)
- [The release script](#the-release-script)
- [Obfuscation and crash symbols](#obfuscation-and-crash-symbols)
- [Upload key (one-time setup)](#upload-key-one-time-setup)
- [Crash reports and analytics](#crash-reports-and-analytics)
- [Play Console › Data safety](#play-console--data-safety)
- [Testing in-app updates](#testing-in-app-updates)
- [Website sync](#website-sync)

---

## Versioning

The version lives in **one place**, `pubspec.yaml`:

```yaml
version: 1.0.0-beta.3+8   # MAJOR.MINOR.PATCH[-alpha.N|-beta.N]+CODE
```

- **Name** (before `+`) is what users see in Settings › About and Settings › Software update. `AppVersion` (`lib/core/config/app_version.dart`) turns it into a label such as "1.0.0 Beta 3".
  - `MAJOR`: big redesigns or breaking changes.
  - `MINOR`: new features.
  - `PATCH`: fixes only.
  - `-alpha.N` and `-beta.N` mark pre-releases.
- **Code** (after `+`) is the Android `versionCode`. It goes up by one for **every** upload to Google Play and is never reused.

| Suffix | Play Console track |
|---|---|
| `-alpha.N` | Internal or Closed testing |
| `-beta.N` | Open testing |
| none | Production |

`test/features/app_version_test.dart` fails if the pubspec version and the newest entry in `lib/core/config/changelog.dart` differ.

## The release script

Don't edit the version by hand. When you're ready to upload, run one command from a clean tree:

| You want to… | Command | Version change |
|---|---|---|
| Start a feature version in beta | `./tool/release.ps1 -Bump minor -Pre beta` | `1.0.0` → `1.1.0-beta.1` |
| Ship the next beta | `./tool/release.ps1 -Pre beta` | `1.1.0-beta.1` → `1.1.0-beta.2` |
| Release it | `./tool/release.ps1 -Promote` | `1.1.0-beta.2` → `1.1.0` |
| Ship a bug fix | `./tool/release.ps1 -Bump patch` | `1.1.0` → `1.1.1` |
| Re-upload the same version | `./tool/release.ps1 -Rebuild` | build number only |

Every one of these also raises the build number.

The script:

1. runs `flutter analyze` and `flutter test`, and stops before changing anything if either fails;
2. bumps `pubspec.yaml`;
3. adds a Changelog entry to `lib/core/config/changelog.dart`, then pauses so you can write the notes;
4. builds `build/app/outputs/bundle/release/app-release.aab`;
5. uploads the Dart symbols to Crashlytics;
6. commits `chore(release): …` and tags `v<name>`.

Then upload the bundle to Play and run `git push --follow-tags`.

- `./tool/release.ps1 -Help` lists every option.
- `./tool/release.ps1 -Debug` builds a debug APK of the current version without changing it.
- Sideload APKs skip x86_64.

Judge app size only from release builds. A `flutter run` or debug APK is about 180 MB, because it includes the JIT VM and every ABI.

## Obfuscation and crash symbols

Release builds use `--obfuscate --split-debug-info=symbols/<version>`. That folder is git-ignored, so keep it: you need it to read that release's crashes.

- **Automatic upload:** the script uploads the symbols with `npx firebase-tools crashlytics:symbols:upload`. Run `npx firebase-tools login` once beforehand.
- **If the upload fails:** the script only warns, and prints the command so you can rerun it.
- **Decoding a trace by hand:** `flutter symbolize -i trace.txt -d symbols/<version>/app.android-arm64.symbols`.
- **Decoding an error message:** Crashlytics decodes stack frames but not messages, so a name like `_Dgb@329498029` stays obfuscated. Look it up in `symbols/<version>.obfuscation-map.json`, saved by each release build. It's a flat `[original, obfuscated, …]` list; ignore the `@…` suffix.
- **Java/Kotlin:** R8 already shrinks and obfuscates it, and the Crashlytics Gradle plugin uploads its mapping.

## Upload key (one-time setup)

Play only accepts bundles signed with your upload key.

1. Create the keystore, and keep it and its passwords somewhere safe outside the repo:

   ```bash
   keytool -genkey -v -keystore C:/Users/<you>/keys/onespend-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `android/key.properties`. It's ignored by git.

   ```properties
   storeFile=C:/Users/<you>/keys/onespend-upload.jks
   storePassword=…
   keyAlias=upload
   keyPassword=…
   ```

Without `key.properties`, release builds are signed with the debug key. `flutter build` allows that for local testing, but the release script stops instead (unless you pass `-SkipBuild`).

The application id is `com.syedarhamraza.onespend`. It can't change once the app is on Google Play.

## Crash reports and analytics

Firebase project **`one-spend`** is connected through `android/app/google-services.json`. That file is committed: it identifies the project and holds no secrets. The Google Services and Crashlytics Gradle plugins are set up in `android/settings.gradle.kts` and `android/app/build.gradle.kts`. Without the file, the app starts normally and falls back to `NoopTelemetry`.

**What sends:**

- Release builds send crash reports and analytics.
- Debug builds don't, unless you run with `--dart-define=TELEMETRY_IN_DEBUG=true`.

**To check it works:**

1. Run:

   ```bash
   flutter run --dart-define=TELEMETRY_IN_DEBUG=true
   ```

2. Tap **Settings › Developer options › Send test error**. It appears in the Crashlytics console within a few minutes. Crash reports are sent the next time the app starts, so restart the app if one doesn't show up.
3. For live analytics, run this, then watch **Analytics › DebugView**:

   ```bash
   adb shell setprop debug.firebase.analytics.app com.syedarhamraza.onespend
   ```

## Play Console › Data safety

Answers for this setup:

| Data type | Collected | Shared | Why |
|---|---|---|---|
| Crash logs | Yes | No | App functionality (crash fixing) |
| Diagnostics | Yes | No | App functionality, Analytics |
| App interactions | Yes | No | Analytics |
| Device or other IDs (Firebase installation ID) | Yes | No | Analytics |

The rest of the form:

- Data is encrypted in transit.
- Collection is required, with no opt-out.
- Users can't ask for deletion in the app: there's no account, and the data isn't linked to a person.
- Under **Advertising ID**, answer **No**: it's removed in the manifest.

Play also needs a **privacy policy URL**. `docs/privacy-policy.md` is published on the [website](#website-sync).

## Testing in-app updates

Play In-App Updates only work on a Play-installed build. `flutter run` and sideloaded builds report "not from Play". To test a real update, use Internal app sharing or an internal-test track with a higher versionCode than the installed build.

## Website sync

The landing page is a separate repo, [syedarhamraza/syedarhamraza.github.io](https://github.com/syedarhamraza/syedarhamraza.github.io), served at <https://syedarhamraza.github.io>. It keeps copies of:

- the store captures (`tool/store_graphics/captures/`),
- the icon and feature graphic (`store/play/`),
- `docs/privacy-policy.md`.

After changing any of them, run this in the site repo and push:

```bash
npm run sync -- ../one-spend
```
