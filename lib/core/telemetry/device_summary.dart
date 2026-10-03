import 'package:device_info_plus/device_info_plus.dart';

import '../config/app_version.dart';

/// "One Spend 1.0.0 Alpha 1 (build 1) · samsung SM-S931U1 · Android 16 (API 36)" for
/// feedback emails, so reports say which build and phone they came from. No user data.
Future<String> deviceSummary() async {
  final version = await AppVersion.current();
  final parts = ['One Spend ${version?.full ?? 'unknown version'}'];
  try {
    final android = await DeviceInfoPlugin().androidInfo;
    parts
      ..add('${android.manufacturer} ${android.model}')
      ..add('Android ${android.version.release} (API ${android.version.sdkInt})');
  } catch (_) {
    // Not Android, or the plugin is unavailable (tests): the version alone still helps.
  }
  return parts.join(' · ');
}
