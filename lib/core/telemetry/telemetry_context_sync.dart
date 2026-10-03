import '../../features/subscriptions/presentation/controllers/subscription_controller.dart';
import '../../theme/one_ui_theme.dart';
import '../config/app_version.dart';
import 'events.dart';
import 'telemetry.dart';

/// Keeps the crash-report context ([TelemetryContext]) in step with the app's setup.
/// Only rough, non-personal values: the currency code, a size bucket and a few toggles.
class TelemetryContextSync {
  final SubscriptionController controller;
  final OneUIEffectsController effects;
  final Map<String, Object> _sent = {};

  TelemetryContextSync({required this.controller, required this.effects});

  Future<void> start() async {
    final version = await AppVersion.current();
    if (version != null) {
      AppLog.context(TelemetryContext.version, version.name);
      AppLog.context(TelemetryContext.build, version.code ?? 0);
      AppLog.context(TelemetryContext.channel, version.channel.name);
    }
    _sync();
    controller.addListener(_sync);
    effects.addListener(_sync);
  }

  void _sync() {
    _set(TelemetryContext.currency, controller.currency);
    _set(TelemetryContext.subscriptions, TelemetryContext.bucket(controller.subscriptions.length));
    _set(TelemetryContext.notifications, controller.notificationsEnabled);
    _set(TelemetryContext.effects3d, effects.floating3dEffect);
  }

  /// Sends a key only when it changed; the controller notifies on every edit.
  void _set(String key, Object value) {
    if (_sent[key] == value) return;
    _sent[key] = value;
    AppLog.context(key, value);
  }
}
