import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Voice typing for search: opens the phone's own voice input screen (usually Google's)
/// through the `onespend/speech` channel (`SpeechChannel.kt`). No microphone permission or
/// speech library is involved; on phones without a voice app, [available] is false and the
/// mic isn't shown.
class VoiceInput {
  const VoiceInput._();

  static const MethodChannel _channel = MethodChannel('onespend/speech');
  static Future<bool>? _available;

  /// Whether a voice input screen exists. Asked once per run.
  static Future<bool> available() => _available ??= _ask();

  static Future<bool> _ask() async {
    try {
      return await _channel.invokeMethod<bool>('available') ?? false;
    } on MissingPluginException {
      return false; // tests and other platforms
    } on PlatformException {
      return false;
    }
  }

  /// Shows the voice input screen with [prompt]; returns what was heard, or null.
  static Future<String?> listen(String prompt) async {
    try {
      final heard = await _channel.invokeMethod<String>('listen', {'prompt': prompt});
      final text = heard?.trim();
      return text == null || text.isEmpty ? null : text;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @visibleForTesting
  static void resetForTesting() => _available = null;
}
