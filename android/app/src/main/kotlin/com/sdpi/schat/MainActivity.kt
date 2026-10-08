package com.sdpi.schat

import android.database.ContentObserver
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.FileObserver
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.app.PictureInPictureParams
import android.content.pm.PackageManager
import android.util.Rational
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.sdpi.schat/screenshot_detector"
    private val PIP_CHANNEL = "com.sdpi.schat/pip"
    private var methodChannel: MethodChannel? = null
    private var pipMethodChannel: MethodChannel? = null
    private var isCallActive = false
    private var contentObserver: ContentObserver? = null
    private var screenCaptureCallback: Any? = null
    private var fileObservers: MutableList<FileObserver> = mutableListOf()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var lastScreenshotTimestamp = 0L

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        if (isVoiceOrAssistantTrigger(intent)) {
            finishAndRemoveTask()
            return
        }
        super.onCreate(savedInstanceState)
        bringActivityToFront()
    }

    override fun onNewIntent(intent: Intent) {
        if (isVoiceOrAssistantTrigger(intent)) {
            finishAndRemoveTask()
            return
        }
        super.onNewIntent(intent)
        setIntent(intent)
        bringActivityToFront()
    }

    override fun onProvideAssistContent(outContent: android.app.assist.AssistContent?) {
        // Block Gemini / Google Assistant from reading active screen context
    }

    override fun onProvideAssistData(data: android.os.Bundle?) {
        // Block Assist Data
    }

    private fun isVoiceOrAssistantTrigger(intent: Intent?): Boolean {
        if (intent == null) return false

        // 1. Check Voice Interaction API (Android 6.0+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                if (isVoiceInteraction || isVoiceInteractionRoot) {
                    return true
                }
            } catch (e: Exception) {
                // ignore
            }
        }

        // 2. Check Intent Categories
        val categories = intent.categories
        if (categories != null && categories.contains(Intent.CATEGORY_VOICE)) {
            return true
        }

        // 3. Check Intent Action
        val action = intent.action ?: ""
        if (action.contains("VOICE", ignoreCase = true) ||
            action == Intent.ACTION_ASSIST ||
            action == "android.intent.action.VOICE_COMMAND" ||
            action == "android.speech.action.VOICE_SEARCH_RESULTS" ||
            action == "android.speech.action.WEB_SEARCH" ||
            action == "com.google.android.gms.actions.SEARCH_ACTION") {
            return true
        }

        // 4. Check Assist Extras
        if (intent.hasExtra("android.intent.extra.ASSIST_PACKAGE") ||
            intent.hasExtra("android.intent.extra.ASSIST_CONTEXT") ||
            intent.hasExtra("android.intent.extra.IS_VOICE_INTERACTION")) {
            return true
        }

        // 5. Check Referrer from Assistant/Gemini
        try {
            @Suppress("DEPRECATION")
            val referrerUri = referrer ?: intent.getParcelableExtra<Uri>(Intent.EXTRA_REFERRER)
            val referrerStr = referrerUri?.toString() ?: intent.getStringExtra("android.intent.extra.REFERRER_NAME") ?: ""
            if (referrerStr.isNotEmpty()) {
                val assistantPackages = listOf(
                    "com.google.android.googlequicksearchbox",
                    "com.google.android.apps.googleassistant",
                    "com.google.android.apps.bard",
                    "com.samsung.android.bixby",
                    "com.samsung.android.bixby.agent"
                )
                for (pkg in assistantPackages) {
                    if (referrerStr.contains(pkg, ignoreCase = true)) {
                        return true
                    }
                }
            }
        } catch (e: Exception) {
            // ignore
        }

        return false
    }

    private fun bringActivityToFront() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguardManager = getSystemService(android.content.Context.KEYGUARD_SERVICE) as? android.app.KeyguardManager
            keyguardManager?.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                android.view.WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        setupScreenshotDetection()

        pipMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PIP_CHANNEL)
        pipMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "setCallActive" -> {
                    isCallActive = call.argument<Boolean>("isActive") ?: false
                    if (isCallActive && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        try {
                            val params = PictureInPictureParams.Builder()
                                .setAspectRatio(Rational(9, 16))
                                .setAutoEnterEnabled(true)
                                .build()
                            setPictureInPictureParams(params)
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                    } else if (!isCallActive && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        try {
                            val params = PictureInPictureParams.Builder()
                                .setAutoEnterEnabled(false)
                                .build()
                            setPictureInPictureParams(params)
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                    }
                    result.success(true)
                }
                "enterPip" -> {
                    val success = enterPipMode()
                    result.success(success)
                }
                "exitPip" -> {
                    try {
                        val intent = Intent(this, MainActivity::class.java).apply {
                            flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        e.printStackTrace()
                        result.success(false)
                    }
                }
                "isPipSupported" -> {
                    result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun enterPipMode(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)) {
            try {
                val builder = PictureInPictureParams.Builder()
                    .setAspectRatio(Rational(9, 16))
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    builder.setAutoEnterEnabled(true)
                }
                val params = builder.build()
                setPictureInPictureParams(params)
                return enterPictureInPictureMode(params)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        return false
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: android.content.res.Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        pipMethodChannel?.invokeMethod("onPipModeChanged", mapOf("isInPip" to isInPictureInPictureMode))
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (isCallActive) {
            enterPipMode()
        }
    }

    private fun setupScreenshotDetection() {
        // 1. Android 14+ (API 34) Official ScreenCaptureCallback
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val callback = ScreenCaptureCallback {
                notifyScreenshotTaken()
            }
            screenCaptureCallback = callback
            try {
                registerScreenCaptureCallback(mainExecutor, callback)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        // 2. ContentObserver for MediaStore changes (Internal + External)
        try {
            contentObserver = object : ContentObserver(mainHandler) {
                override fun onChange(selfChange: Boolean, uri: Uri?) {
                    super.onChange(selfChange, uri)
                    checkAndNotifyScreenshot(uri)
                }
            }

            contentResolver.registerContentObserver(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                true,
                contentObserver!!
            )
            contentResolver.registerContentObserver(
                MediaStore.Images.Media.INTERNAL_CONTENT_URI,
                true,
                contentObserver!!
            )
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // 3. Direct FileObservers on common Screenshot paths
        setupFileObservers()
    }

    private fun setupFileObservers() {
        val paths = listOf(
            File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), "Screenshots"),
            File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM), "Screenshots"),
            File("/storage/emulated/0/Pictures/Screenshots"),
            File("/storage/emulated/0/DCIM/Screenshots")
        )

        for (dir in paths) {
            if (dir.exists() || dir.mkdirs()) {
                try {
                    val observer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        object : FileObserver(dir, CREATE or CLOSE_WRITE) {
                            override fun onEvent(event: Int, path: String?) {
                                if (path != null && (path.contains("screenshot", ignoreCase = true) || path.endsWith(".jpg") || path.endsWith(".png"))) {
                                    notifyScreenshotTaken()
                                }
                            }
                        }
                    } else {
                        @Suppress("DEPRECATION")
                        object : FileObserver(dir.absolutePath, CREATE or CLOSE_WRITE) {
                            override fun onEvent(event: Int, path: String?) {
                                if (path != null && (path.contains("screenshot", ignoreCase = true) || path.endsWith(".jpg") || path.endsWith(".png"))) {
                                    notifyScreenshotTaken()
                                }
                            }
                        }
                    }
                    observer.startWatching()
                    fileObservers.add(observer)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }

    private fun checkAndNotifyScreenshot(uri: Uri?) {
        val now = System.currentTimeMillis()
        if (now - lastScreenshotTimestamp < 1500) {
            return
        }

        if (uri != null) {
            val uriStr = uri.toString().lowercase()
            if (uriStr.contains("screenshot") || uriStr.contains("media")) {
                notifyScreenshotTaken()
                return
            }
        }

        try {
            val projection = arrayOf(
                MediaStore.Images.Media.DISPLAY_NAME,
                MediaStore.Images.Media.DATA,
                MediaStore.Images.Media.DATE_ADDED
            )
            val cursor = contentResolver.query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                projection,
                null,
                null,
                "${MediaStore.Images.Media.DATE_ADDED} DESC"
            )
            cursor?.use {
                if (it.moveToFirst()) {
                    val nameIndex = it.getColumnIndex(MediaStore.Images.Media.DISPLAY_NAME)
                    val dataIndex = it.getColumnIndex(MediaStore.Images.Media.DATA)
                    val name = if (nameIndex >= 0) it.getString(nameIndex)?.lowercase() ?: "" else ""
                    val path = if (dataIndex >= 0) it.getString(dataIndex)?.lowercase() ?: "" else ""

                    if (name.contains("screenshot") || path.contains("screenshot")) {
                        notifyScreenshotTaken()
                    }
                }
            }
        } catch (e: Exception) {
            notifyScreenshotTaken()
        }
    }

    private fun notifyScreenshotTaken() {
        val now = System.currentTimeMillis()
        if (now - lastScreenshotTimestamp < 1500) {
            return
        }
        lastScreenshotTimestamp = now
        mainHandler.post {
            methodChannel?.invokeMethod("onScreenshot", null)
        }
    }

    override fun onDestroy() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            (screenCaptureCallback as? ScreenCaptureCallback)?.let {
                try {
                    unregisterScreenCaptureCallback(it)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
        contentObserver?.let {
            try {
                contentResolver.unregisterContentObserver(it)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        for (observer in fileObservers) {
            try {
                observer.stopWatching()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        fileObservers.clear()
        super.onDestroy()
    }
}
