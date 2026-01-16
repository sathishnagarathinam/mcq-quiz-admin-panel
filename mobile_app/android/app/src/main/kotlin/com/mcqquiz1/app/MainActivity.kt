package com.mcqquiz1.app

import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val SECURITY_CHANNEL = "security/screenshots"
    private val SCREEN_RECORDING_CHANNEL = "security/screen_recording"
    private var secureOverlay: View? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // TEMPORARILY DISABLED: Enable protection BEFORE calling super.onCreate
        // enableMaximumScreenshotProtection()
        super.onCreate(savedInstanceState)

        // TEMPORARILY DISABLED: Apply additional protection layers
        // applySecurityLayers()
    }

    override fun onResume() {
        super.onResume()
        // TEMPORARILY DISABLED: Screenshot protection
        // enableMaximumScreenshotProtection()
        // applySecurityLayers()
    }

    override fun onStart() {
        super.onStart()
        // TEMPORARILY DISABLED: Screenshot protection
        // enableMaximumScreenshotProtection()
    }

    override fun onRestart() {
        super.onRestart()
        // TEMPORARILY DISABLED: Screenshot protection
        // enableMaximumScreenshotProtection()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        // TEMPORARILY DISABLED: Screenshot protection
        // if (hasFocus) {
        //     enableMaximumScreenshotProtection()
        // }
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        // TEMPORARILY DISABLED: Screenshot protection
        // enableMaximumScreenshotProtection()
    }

    private fun enableMaximumScreenshotProtection() {
        try {
            // Primary protection: FLAG_SECURE
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE
            )

            // Additional security flags
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)

            // Prevent screenshots in recent apps
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)

            // Force immediate application
            window.decorView.invalidate()

            android.util.Log.d("ScreenshotProtection", "Maximum protection enabled - FLAG_SECURE applied")
        } catch (e: Exception) {
            android.util.Log.e("ScreenshotProtection", "Error enabling maximum protection: ${e.message}")
        }
    }

    private fun applySecurityLayers() {
        try {
            // Layer 1: Secure window attributes
            window.attributes = window.attributes.apply {
                flags = flags or WindowManager.LayoutParams.FLAG_SECURE
            }

            // Layer 2: Hide from recent apps
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)

            // Layer 3: Additional security overlay (invisible)
            addSecureOverlay()

            android.util.Log.d("ScreenshotProtection", "All security layers applied")
        } catch (e: Exception) {
            android.util.Log.e("ScreenshotProtection", "Error applying security layers: ${e.message}")
        }
    }

    private fun addSecureOverlay() {
        try {
            if (secureOverlay == null) {
                secureOverlay = View(this).apply {
                    layoutParams = FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.MATCH_PARENT,
                        FrameLayout.LayoutParams.MATCH_PARENT
                    )
                    setBackgroundColor(Color.TRANSPARENT)
                    isClickable = false
                    isFocusable = false
                }

                // Add overlay to window
                (window.decorView as? FrameLayout)?.addView(secureOverlay, 0)
            }
        } catch (e: Exception) {
            android.util.Log.e("ScreenshotProtection", "Error adding secure overlay: ${e.message}")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Screenshot prevention channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURITY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "preventScreenshots" -> {
                    val prevent = call.arguments as Boolean
                    preventScreenshots(prevent)
                    result.success(null)
                }
                "testScreenshotProtection" -> {
                    val isProtected = testScreenshotProtection()
                    result.success(isProtected)
                }
                else -> result.notImplemented()
            }
        }

        // Screen recording prevention channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_RECORDING_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "preventScreenRecording" -> {
                    val prevent = call.arguments as Boolean
                    preventScreenRecording(prevent)
                    result.success(null)
                }
                "isScreenRecordingActive" -> {
                    // Android doesn't have a direct way to detect screen recording
                    // This would require more complex implementation
                    result.success(false)
                }
                "startMonitoring" -> {
                    // Start monitoring for screen recording (if possible)
                    result.success(null)
                }
                "showRecordingWarning" -> {
                    // Show warning about screen recording
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun preventScreenshots(prevent: Boolean) {
        try {
            if (prevent) {
                // Enable screenshot prevention
                enableMaximumScreenshotProtection()
                applySecurityLayers()
                android.util.Log.d("ScreenshotProtection", "✅ Screenshot prevention ENABLED via method channel")
            } else {
                // Disable screenshot prevention
                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                secureOverlay?.let { overlay ->
                    (window.decorView as? FrameLayout)?.removeView(overlay)
                    secureOverlay = null
                }
                android.util.Log.d("ScreenshotProtection", "❌ Screenshot prevention DISABLED via method channel")
            }
        } catch (e: Exception) {
            android.util.Log.e("ScreenshotProtection", "Error in preventScreenshots: ${e.message}")
        }
    }

    private fun preventScreenRecording(prevent: Boolean) {
        try {
            // On Android, FLAG_SECURE also prevents screen recording
            if (prevent) {
                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                android.util.Log.d("ScreenshotProtection", "✅ Screen recording prevention ENABLED")
            } else {
                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                android.util.Log.d("ScreenshotProtection", "❌ Screen recording prevention DISABLED")
            }
        } catch (e: Exception) {
            android.util.Log.e("ScreenshotProtection", "Error in preventScreenRecording: ${e.message}")
        }
    }

    private fun testScreenshotProtection(): Boolean {
        return try {
            // Check if FLAG_SECURE is set
            val flags = window.attributes.flags
            val isSecure = (flags and WindowManager.LayoutParams.FLAG_SECURE) != 0

            android.util.Log.d("ScreenshotProtection", "FLAG_SECURE status: $isSecure")
            android.util.Log.d("ScreenshotProtection", "Window flags: $flags")

            isSecure
        } catch (e: Exception) {
            android.util.Log.e("ScreenshotProtection", "Error testing protection: ${e.message}")
            false
        }
    }
}
