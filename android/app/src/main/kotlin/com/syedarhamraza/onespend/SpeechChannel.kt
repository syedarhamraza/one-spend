package com.syedarhamraza.onespend

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.speech.RecognizerIntent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Voice typing for search fields, for Dart's `VoiceInput`. It opens the phone's own voice
 * input screen (usually Google's), so One Spend needs no microphone permission and no
 * speech library.
 *
 * - `available`: whether a voice input screen is installed.
 * - `listen(prompt)`: shows it and returns the first thing heard, or null if cancelled.
 *
 * The manifest's `<queries>` entry lets Android 11+ see the voice app.
 */
class SpeechChannel(private val activity: Activity, messenger: BinaryMessenger) {
    private var pending: MethodChannel.Result? = null

    init {
        MethodChannel(messenger, "onespend/speech").setMethodCallHandler { call, result ->
            when (call.method) {
                "available" -> result.success(intent(null).resolveActivity(activity.packageManager) != null)
                "listen" -> listen(call.argument<String>("prompt"), result)
                else -> result.notImplemented()
            }
        }
    }

    private fun intent(prompt: String?) = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
        putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
        putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
        if (prompt != null) putExtra(RecognizerIntent.EXTRA_PROMPT, prompt)
    }

    private fun listen(prompt: String?, result: MethodChannel.Result) {
        // One voice screen at a time; a second tap while it opens gets nothing.
        if (pending != null) {
            result.success(null)
            return
        }
        pending = result
        try {
            activity.startActivityForResult(intent(prompt), REQUEST_CODE)
        } catch (e: ActivityNotFoundException) {
            pending = null
            result.success(null)
        }
    }

    /** Called from [MainActivity.onActivityResult]; true when the result was ours. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val heard = if (resultCode == Activity.RESULT_OK) {
            data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)?.firstOrNull()
        } else {
            null
        }
        pending?.success(heard)
        pending = null
        return true
    }

    companion object {
        private const val REQUEST_CODE = 0x5EEC
    }
}
