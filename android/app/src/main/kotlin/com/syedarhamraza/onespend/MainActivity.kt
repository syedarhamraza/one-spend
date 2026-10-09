package com.syedarhamraza.onespend

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var speech: SpeechChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Device details for Dart, e.g. OneUIToast skips "Copied" toasts on
        // Android 13+ because the system confirms copies itself.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "onespend/device").setMethodCallHandler { call, result ->
            when (call.method) {
                "sdkInt" -> result.success(Build.VERSION.SDK_INT)
                else -> result.notImplemented()
            }
        }
        HapticsChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        speech = SpeechChannel(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    @Deprecated("Flutter's FlutterActivity still delivers results here")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (speech?.onActivityResult(requestCode, resultCode, data) == true) return
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }
}
