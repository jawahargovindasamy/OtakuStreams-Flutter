package com.jawahargovindasamy.otakustreams.otakustreams

import android.app.PictureInPictureParams
import android.content.pm.ActivityInfo
import android.content.res.Configuration
import android.os.Build
import android.util.Log
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val TAG = "OtakuStreamsPiP"
    private val CHANNEL = "com.jawahargovindasamy.otakustreams/orientation"
    private var methodChannel: MethodChannel? = null
    private var isWatchScreenActive = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "setSensorLandscape" -> {
                    runOnUiThread { requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE }
                    result.success(null)
                }
                "resetOrientation" -> {
                    runOnUiThread { requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED }
                    result.success(null)
                }
                "setWatchScreenActive" -> {
                    val active = call.arguments as? Boolean ?: false
                    isWatchScreenActive = active
                    Log.d(TAG, "setWatchScreenActive: $isWatchScreenActive")
                    // Pre-register PiP params so the system is ready when Home is pressed
                    if (active && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        runOnUiThread {
                            try {
                                setPictureInPictureParams(
                                    PictureInPictureParams.Builder()
                                        .setAspectRatio(Rational(16, 9))
                                        .build()
                                )
                                Log.d(TAG, "PiP params pre-registered")
                            } catch (e: Exception) {
                                Log.e(TAG, "setPictureInPictureParams failed", e)
                            }
                        }
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    // Called when the user presses Home or Recents while the app is in the foreground
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        Log.d(TAG, "onUserLeaveHint: isWatchScreenActive=$isWatchScreenActive")
        if (isWatchScreenActive && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val entered = enterPictureInPictureMode(
                    PictureInPictureParams.Builder()
                        .setAspectRatio(Rational(16, 9))
                        .build()
                )
                Log.d(TAG, "Auto-entered PiP on Home press: $entered")
            } catch (e: Exception) {
                Log.e(TAG, "Auto-enter PiP failed", e)
            }
        }
    }

    // API 26-30
    @Suppress("OVERRIDE_DEPRECATION")
    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode)
        Log.d(TAG, "PiP mode changed: $isInPictureInPictureMode")
        methodChannel?.invokeMethod("onPipModeChanged", isInPictureInPictureMode)
    }

    // API 31+
    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        Log.d(TAG, "PiP mode changed (new): $isInPictureInPictureMode")
        methodChannel?.invokeMethod("onPipModeChanged", isInPictureInPictureMode)
    }
}
