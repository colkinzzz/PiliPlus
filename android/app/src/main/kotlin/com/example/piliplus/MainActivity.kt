package com.example.piliplus

import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.util.DisplayMetrics
import android.view.WindowInsets
import android.view.WindowManager.LayoutParams
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    companion object {
        private const val CAR_WINDOW_CHANNEL = "com.example.piliplus/car_window"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CAR_WINDOW_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getWindowState" -> result.success(readWindowState())
                else -> result.notImplemented()
            }
        }
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        if (AndroidHelper.isFoldable) {
            AndroidHelper.ToDart.onConfigurationChanged?.run()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes.layoutInDisplayCutoutMode =
                LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }
    }

    override fun onDestroy() {
        stopService(Intent(this, com.ryanheise.audioservice.AudioService::class.java))
        super.onDestroy()
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        AndroidHelper.ToDart.onUserLeaveHint?.run()
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration?) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        AndroidHelper.isPipMode = isInPictureInPictureMode
    }

    @Suppress("DEPRECATION")
    private fun readPhysicalDisplayMetrics(): DisplayMetrics {
        val metrics = DisplayMetrics()
        val targetDisplay = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            display
        } else {
            windowManager.defaultDisplay
        }
        targetDisplay?.getRealMetrics(metrics)
        if (metrics.widthPixels <= 0 || metrics.heightPixels <= 0) {
            windowManager.defaultDisplay.getRealMetrics(metrics)
        }
        return metrics
    }

    private fun readWindowState(): Map<String, Any> {
        val density = resources.displayMetrics.density.toDouble().coerceAtLeast(1.0)
        val isMultiWindow = Build.VERSION.SDK_INT >= Build.VERSION_CODES.N &&
            isInMultiWindowMode
        val isAutomotive = packageManager.hasSystemFeature(
            PackageManager.FEATURE_AUTOMOTIVE,
        )
        val physicalMetrics = readPhysicalDisplayMetrics()
        val physicalWidth = physicalMetrics.widthPixels.coerceAtLeast(1)
        val physicalHeight = physicalMetrics.heightPixels.coerceAtLeast(1)

        val currentWidth: Int
        val currentHeight: Int
        var insetLeft = 0
        var insetTop = 0
        var insetRight = 0
        var insetBottom = 0
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val currentMetrics = windowManager.currentWindowMetrics
            val bounds = currentMetrics.bounds
            currentWidth = bounds.width()
            currentHeight = bounds.height()
            val insetTypes = WindowInsets.Type.statusBars() or
                WindowInsets.Type.navigationBars() or
                WindowInsets.Type.displayCutout() or
                WindowInsets.Type.tappableElement() or
                WindowInsets.Type.mandatorySystemGestures()
            val insets = currentMetrics.windowInsets.getInsetsIgnoringVisibility(insetTypes)
            insetLeft = insets.left
            insetTop = insets.top
            insetRight = insets.right
            insetBottom = insets.bottom
        } else {
            currentWidth = window.decorView.width.takeIf { it > 0 }
                ?: resources.displayMetrics.widthPixels
            currentHeight = window.decorView.height.takeIf { it > 0 }
                ?: resources.displayMetrics.heightPixels
        }

        // This OEM split is not reported through isInMultiWindowMode, and its
        // maximumWindowMetrics can be scoped to the current task. The Activity
        // width is about 0.67 of the physical panel in split and 1.0 when full.
        val widthRatio = currentWidth.toDouble() / physicalWidth
        val isHostFullScreen = widthRatio >= 0.90

        return mapOf(
            "isAutomotive" to isAutomotive,
            "isInMultiWindowMode" to isMultiWindow,
            "isHostFullScreen" to isHostFullScreen,
            "width" to currentWidth / density,
            "height" to currentHeight / density,
            "maximumWidth" to physicalWidth / density,
            "maximumHeight" to physicalHeight / density,
            "widthRatio" to widthRatio,
            "insetLeft" to insetLeft / density,
            "insetTop" to insetTop / density,
            "insetRight" to insetRight / density,
            "insetBottom" to insetBottom / density,
        )
    }
}
