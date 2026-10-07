package com.syedarhamraza.onespend

import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Touch haptics at a chosen strength (Settings › Vibration › Intensity), for Dart's `Haptics`.
 *
 * - Phones with a haptic motor (Android 11+ click and tick primitives) get crisp clicks,
 *   scaled by strength.
 * - Phones that can only set a strength get short pulses at that amplitude.
 * - Basic motors report `canAdjust = false`, and Dart keeps using the system's own haptics.
 *
 * Vibrations are tagged as touch feedback, so turning touch feedback off in the phone's
 * settings silences them too.
 */
class HapticsChannel(private val context: Context, messenger: BinaryMessenger) {
    private val vibrator: Vibrator? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }

    init {
        MethodChannel(messenger, "onespend/haptics").setMethodCallHandler { call, result ->
            when (call.method) {
                "info" -> result.success(mapOf("canAdjust" to canAdjust(), "rich" to hasPrimitives()))
                "play" -> {
                    play(call.argument<String>("kind") ?: "tap", call.argument<Double>("strength") ?: 0.6)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasPrimitives(): Boolean {
        val v = vibrator ?: return false
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return false
        return v.areAllPrimitivesSupported(
            VibrationEffect.Composition.PRIMITIVE_CLICK,
            VibrationEffect.Composition.PRIMITIVE_TICK,
        )
    }

    private fun canAdjust(): Boolean {
        val v = vibrator ?: return false
        if (!v.hasVibrator() || Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        return hasPrimitives() || v.hasAmplitudeControl()
    }

    /** Before Android 13 a raw vibration ignores the touch feedback setting, so check it here. */
    private fun touchFeedbackOn(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) return true
        return Settings.System.getInt(context.contentResolver, Settings.System.HAPTIC_FEEDBACK_ENABLED, 1) != 0
    }

    private fun play(kind: String, strength: Double) {
        val v = vibrator ?: return
        if (!canAdjust() || !touchFeedbackOn()) return
        val s = strength.coerceIn(0.05, 1.0).toFloat()
        val effect = if (hasPrimitives()) composed(kind, s) else pulsed(kind, s)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            v.vibrate(effect, VibrationAttributes.createForUsage(VibrationAttributes.USAGE_TOUCH))
        } else {
            @Suppress("DEPRECATION")
            v.vibrate(
                effect,
                AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION).build(),
            )
        }
    }

    /** Haptic-motor clicks. Each kind keeps its place relative to the others at any strength. */
    private fun composed(kind: String, s: Float): VibrationEffect {
        val tick = VibrationEffect.Composition.PRIMITIVE_TICK
        val click = VibrationEffect.Composition.PRIMITIVE_CLICK
        val c = VibrationEffect.startComposition()
        when (kind) {
            "select" -> c.addPrimitive(tick, s)
            "tap" -> c.addPrimitive(click, s * 0.7f)
            "confirm" -> c.addPrimitive(click, s)
            "longPress" -> c.addPrimitive(click, s).addPrimitive(tick, s * 0.8f, 40)
            "warn" -> c.addPrimitive(click, s).addPrimitive(click, s, 70)
            else -> c.addPrimitive(click, s * 0.7f)
        }
        return c.compose()
    }

    /** Short pulses at an amplitude, for motors without primitives. */
    private fun pulsed(kind: String, s: Float): VibrationEffect {
        val amp = (s * 255).toInt().coerceIn(1, 255)
        return when (kind) {
            "select" -> VibrationEffect.createOneShot(10, (amp * 0.7).toInt().coerceAtLeast(1))
            "confirm" -> VibrationEffect.createOneShot(22, amp)
            "longPress" -> VibrationEffect.createOneShot(35, amp)
            "warn" -> VibrationEffect.createWaveform(longArrayOf(0, 22, 70, 22), intArrayOf(0, amp, 0, amp), -1)
            else -> VibrationEffect.createOneShot(14, amp)
        }
    }
}
