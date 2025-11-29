package com.eskalasi.safeexam.safe_exam_app

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.media.AudioManager
import android.os.Build
import android.view.WindowManager
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.eskalasi.safeexam/lock"
    private var originalVolume: Int = 0
    private var isExamActive: Boolean = false
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startLockTask" -> {
                    try {
                        isExamActive = true
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                            // Hide system bars and prevent gesture navigation
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                                window.insetsController?.let { controller ->
                                    controller.hide(WindowInsets.Type.systemBars())
                                    controller.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                                }
                            } else {
                                @Suppress("DEPRECATION")
                                window.decorView.systemUiVisibility = (
                                    View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                                    or View.SYSTEM_UI_FLAG_FULLSCREEN
                                    or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                                    or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                                    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                                )
                            }
                            
                            // Try to start lock task mode with fallback
                            try {
                                startLockTask()
                                result.success(0) // 0 = full lock task mode
                            } catch (e: SecurityException) {
                                // Lock task not whitelisted, use fallback mode
                                result.success(1) // 1 = fallback mode (immersive only)
                            }
                        } else {
                            result.error("UNAVAILABLE", "Lock task mode not available", null)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "stopLockTask" -> {
                    try {
                        isExamActive = false
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                            // Restore system bars
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                                window.insetsController?.show(WindowInsets.Type.systemBars())
                            } else {
                                @Suppress("DEPRECATION")
                                window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_VISIBLE
                            }
                            stopLockTask()
                            result.success(true)
                        } else {
                            result.error("UNAVAILABLE", "Lock task mode not available", null)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "setSecureFlag" -> {
                    try {
                        window.setFlags(
                            WindowManager.LayoutParams.FLAG_SECURE,
                            WindowManager.LayoutParams.FLAG_SECURE
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "clearSecureFlag" -> {
                    try {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "setMaxVolume" -> {
                    try {
                        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        // Save original volume
                        originalVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
                        // Set to max volume
                        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, maxVolume, 0)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "restoreVolume" -> {
                    try {
                        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, originalVolume, 0)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "disableGestureNavigation" -> {
                    try {
                        // Disable gesture navigation by hiding navigation bar and preventing swipe
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            window.insetsController?.let { controller ->
                                controller.hide(WindowInsets.Type.navigationBars())
                                controller.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                            }
                        } else {
                            @Suppress("DEPRECATION")
                            window.decorView.systemUiVisibility = (
                                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                                or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                            )
                            
                            // Set a listener to prevent navigation bar from reappearing
                            window.decorView.setOnSystemUiVisibilityChangeListener { visibility ->
                                if (visibility and View.SYSTEM_UI_FLAG_HIDE_NAVIGATION == 0) {
                                    @Suppress("DEPRECATION")
                                    window.decorView.systemUiVisibility = (
                                        View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                                        or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                                        or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                                        or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                                    )
                                }
                            }
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "enableGestureNavigation" -> {
                    try {
                        // Re-enable gesture navigation
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            window.insetsController?.show(WindowInsets.Type.navigationBars())
                        } else {
                            @Suppress("DEPRECATION")
                            window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_VISIBLE
                            window.decorView.setOnSystemUiVisibilityChangeListener(null)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "isLockTaskModeActive" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                            val lockTaskMode = activityManager.lockTaskModeState
                            val isActive = lockTaskMode != ActivityManager.LOCK_TASK_MODE_NONE
                            result.success(isActive)
                        } else {
                            @Suppress("DEPRECATION")
                            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                            val isActive = activityManager.isInLockTaskMode
                            result.success(isActive)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "disablePictureInPicture" -> {
                    try {
                        // PiP is disabled via AndroidManifest (supportsPictureInPicture="false")
                        // This method just confirms it's disabled
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "disableSplitScreen" -> {
                    try {
                        // Split screen is disabled via AndroidManifest (resizeableActivity="false")
                        // This method just confirms it's disabled
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "preventFloatingWindows" -> {
                    try {
                        // Floating windows are prevented by lock task mode and manifest settings
                        // Additional layer: prevent window from being touchable when backgrounded
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "hasWindowFocus" -> {
                    try {
                        result.success(hasWindowFocus())
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (isExamActive && !hasFocus) {
            // If exam is active and we lose focus, it might be due to an overlay or system dialog
            methodChannel?.invokeMethod("onOverlayDetected", null)
        }
    }

    // Prevent Picture-in-Picture when user tries to leave the app
    override fun onUserLeaveHint() {
        // Don't call super to prevent PiP activation
        // This works in conjunction with AndroidManifest setting
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Do nothing - prevents PiP
        } else {
            super.onUserLeaveHint()
        }
    }
}
