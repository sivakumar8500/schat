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
import android.media.AudioManager
import android.content.Context
import android.telephony.TelephonyManager
import android.telecom.TelecomManager
import java.io.File
import android.media.MediaScannerConnection
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.sdpi.schat/screenshot_detector"
    private val PIP_CHANNEL = "com.sdpi.schat/pip"
    private val PHONE_CALL_CHANNEL = "com.sdpi.schat/phone_call_state"
    private val AUDIO_ROUTING_CHANNEL = "com.sdpi.schat/audio_routing"
    private var methodChannel: MethodChannel? = null
    private var pipMethodChannel: MethodChannel? = null
    private var phoneCallChannel: MethodChannel? = null
    private var audioRoutingChannel: MethodChannel? = null
    private var isCallActive = false
    private var contentObserver: ContentObserver? = null
    private var screenCaptureCallback: Any? = null
    private var fileObservers: MutableList<FileObserver> = mutableListOf()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var lastScreenshotTimestamp = 0L
    private var wasPhoneCallActive = false
    private var telephonyCallback: Any? = null
    private var phoneStateListener: android.telephony.PhoneStateListener? = null
    private var isScreenRecordingOnlyMode = false
    private var lastScreenshotUri: Uri? = null
    private var lastScreenshotPath: String? = null
    private var lastScreenshotMediaId: Long = -1L

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
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "setScreenRecordingMode" -> {
                    isScreenRecordingOnlyMode = call.argument<Boolean>("isRecording") ?: false
                    result.success(true)
                }
                "deleteLastScreenshot" -> {
                    val deleted = deleteLastScreenshot()
                    result.success(deleted)
                }
                "saveLatestScreenRecordingToSchat" -> {
                    val recordedSinceTimestamp = call.argument<Long>("recordedSinceTimestamp") ?: (System.currentTimeMillis() - 10 * 60 * 1000L)
                    val savedPath = saveLatestScreenRecordingToSchat(recordedSinceTimestamp)
                    result.success(savedPath)
                }
                "saveScreenshot" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    val fileName = call.argument<String>("fileName")
                    if (bytes != null) {
                        val savedPath = saveScreenshotToStorage(bytes, fileName)
                        result.success(savedPath)
                    } else {
                        result.error("INVALID_ARGS", "bytes cannot be null", null)
                    }
                }
                "scanFile" -> {
                    val path = call.argument<String>("path")
                    val mimeType = call.argument<String>("mimeType")
                    if (path != null) {
                        MediaScannerConnection.scanFile(
                            applicationContext,
                            arrayOf(path),
                            if (mimeType != null) arrayOf(mimeType) else null,
                            null
                        )
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
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

        phoneCallChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PHONE_CALL_CHANNEL)
        phoneCallChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isPhoneCallActive" -> {
                    result.success(isSystemPhoneCallActive())
                }
                else -> result.notImplemented()
            }
        }

        audioRoutingChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_ROUTING_CHANNEL)
        audioRoutingChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "setCallAudioMode" -> {
                    try {
                        val speakerOn = call.argument<Boolean>("speakerOn") ?: true
                        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
                        audioManager.isSpeakerphoneOn = speakerOn
                        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_VOICE_CALL)
                        audioManager.setStreamVolume(AudioManager.STREAM_VOICE_CALL, maxVolume, 0)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "resetAudioMode" -> {
                    try {
                        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        audioManager.isSpeakerphoneOn = false
                        audioManager.mode = AudioManager.MODE_NORMAL
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
        setupPhoneStateListener()
    }

    private fun setupPhoneStateListener() {
        try {
            val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager ?: return
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val callback = object : android.telephony.TelephonyCallback(), android.telephony.TelephonyCallback.CallStateListener {
                    override fun onCallStateChanged(state: Int) {
                        handleCallStateChange(state)
                    }
                }
                telephonyCallback = callback
                telephonyManager.registerTelephonyCallback(mainExecutor, callback)
            } else {
                @Suppress("DEPRECATION")
                phoneStateListener = object : android.telephony.PhoneStateListener() {
                    @Deprecated("Deprecated in Java")
                    override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                        super.onCallStateChanged(state, phoneNumber)
                        handleCallStateChange(state)
                    }
                }
                @Suppress("DEPRECATION")
                telephonyManager.listen(phoneStateListener, android.telephony.PhoneStateListener.LISTEN_CALL_STATE)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun handleCallStateChange(state: Int) {
        val isActive = state == TelephonyManager.CALL_STATE_OFFHOOK || state == TelephonyManager.CALL_STATE_RINGING
        if (isActive && !wasPhoneCallActive) {
            wasPhoneCallActive = true
            mainHandler.post {
                phoneCallChannel?.invokeMethod("onPhoneCallStarted", null)
            }
        } else if (!isActive && wasPhoneCallActive) {
            wasPhoneCallActive = false
            mainHandler.post {
                phoneCallChannel?.invokeMethod("onPhoneCallEnded", null)
            }
        }
    }

    private fun isSystemPhoneCallActive(): Boolean {
        if (wasPhoneCallActive) return true
        try {
            val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
            if (telephonyManager != null) {
                @Suppress("DEPRECATION")
                val callState = telephonyManager.callState
                if (callState == TelephonyManager.CALL_STATE_OFFHOOK || callState == TelephonyManager.CALL_STATE_RINGING) {
                    return true
                }
            }
        } catch (e: Exception) {
            // ignore silently
        }
        return false
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
        if (now - lastScreenshotTimestamp < 300) {
            return
        }

        if (uri != null) {
            val uriStr = uri.toString().lowercase()
            if (uriStr.contains("screenshot") || uriStr.contains("media")) {
                lastScreenshotUri = uri
                if (isScreenRecordingOnlyMode) {
                    deleteLastScreenshot()
                    mainHandler.post {
                        try {
                            window.addFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE)
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                    }
                }
                notifyScreenshotTaken()
                return
            }
        }

        try {
            val projection = arrayOf(
                MediaStore.Images.Media._ID,
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
                    val idIndex = it.getColumnIndex(MediaStore.Images.Media._ID)
                    val nameIndex = it.getColumnIndex(MediaStore.Images.Media.DISPLAY_NAME)
                    val dataIndex = it.getColumnIndex(MediaStore.Images.Media.DATA)
                    val name = if (nameIndex >= 0) it.getString(nameIndex)?.lowercase() ?: "" else ""
                    val path = if (dataIndex >= 0) it.getString(dataIndex) ?: "" else ""
                    val mediaId = if (idIndex >= 0) it.getLong(idIndex) else -1L

                    if (name.contains("screenshot") || path.lowercase().contains("screenshot")) {
                        if (mediaId != -1L && mediaId == lastScreenshotMediaId && (now - lastScreenshotTimestamp < 1000)) {
                            // Exact same MediaStore entry already handled within 1 second
                            return
                        }
                        lastScreenshotMediaId = mediaId
                        lastScreenshotPath = path
                        if (idIndex >= 0) {
                            val id = it.getLong(idIndex)
                            lastScreenshotUri = android.content.ContentUris.withAppendedId(
                                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                                id
                            )
                        }
                        if (isScreenRecordingOnlyMode) {
                            deleteLastScreenshot()
                            mainHandler.post {
                                try {
                                    window.addFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE)
                                } catch (e: Exception) {
                                    e.printStackTrace()
                                }
                            }
                        }
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
        if (now - lastScreenshotTimestamp < 300) {
            return
        }
        lastScreenshotTimestamp = now
        mainHandler.post {
            methodChannel?.invokeMethod("onScreenshot", null)
        }
    }

    private fun deleteLastScreenshot(): Boolean {
        var deleted = false
        try {
            val path = lastScreenshotPath
            if (!path.isNullOrEmpty()) {
                val f = File(path)
                if (f.exists()) {
                    deleted = f.delete() || deleted
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        try {
            val uri = lastScreenshotUri
            if (uri != null) {
                val rows = contentResolver.delete(uri, null, null)
                if (rows > 0) deleted = true
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        lastScreenshotPath = null
        lastScreenshotUri = null
        return deleted
    }

    private fun saveLatestScreenRecordingToSchat(recordedSinceTimestamp: Long): String? {
        try {
            val schatFolder = File("/storage/emulated/0/Download/Schat")
            if (!schatFolder.exists()) {
                schatFolder.mkdirs()
            }

            var latestUri: Uri? = null
            var latestFile: File? = null
            var newestTimestamp = 0L

            // 1. Check direct directories on storage (including Vivo/iQOO Pictures/Screenshots)
            val candidateDirs = listOf(
                File("/storage/emulated/0/Pictures/Screenshots"),
                File("/storage/emulated/0/Pictures/Screenrecords"),
                File("/storage/emulated/0/Pictures"),
                File("/storage/emulated/0/Movies/Screenrecords"),
                File("/storage/emulated/0/Movies"),
                File("/storage/emulated/0/DCIM/Screenrecords"),
                File("/storage/emulated/0/DCIM/Screenshots"),
                File("/storage/emulated/0/DCIM"),
                File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), "Screenshots"),
                File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), "Screenrecords"),
                File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), ""),
                File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES), "Screenrecords"),
                File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES), ""),
                File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM), "Screenrecords"),
                File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM), "")
            )

            for (dir in candidateDirs) {
                if (dir.exists() && dir.isDirectory) {
                    val files = dir.listFiles() ?: continue
                    for (f in files) {
                        if (f.isFile && f.extension.equals("mp4", ignoreCase = true)) {
                            val lm = f.lastModified()
                            if (lm > newestTimestamp && lm >= (recordedSinceTimestamp - 180000L)) {
                                newestTimestamp = lm
                                latestFile = f
                            }
                        }
                    }
                }
            }

            // 2. Also query MediaStore.Video.Media
            try {
                val projection = arrayOf(
                    MediaStore.Video.Media._ID,
                    MediaStore.Video.Media.DISPLAY_NAME,
                    MediaStore.Video.Media.DATA,
                    MediaStore.Video.Media.DATE_ADDED,
                    MediaStore.Video.Media.DATE_MODIFIED
                )
                val cursor = contentResolver.query(
                    MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                    projection,
                    null,
                    null,
                    "${MediaStore.Video.Media.DATE_ADDED} DESC"
                )
                cursor?.use {
                    while (it.moveToNext()) {
                        val idIndex = it.getColumnIndex(MediaStore.Video.Media._ID)
                        val dataIndex = it.getColumnIndex(MediaStore.Video.Media.DATA)
                        val dateIndex = it.getColumnIndex(MediaStore.Video.Media.DATE_ADDED)

                        val id = if (idIndex >= 0) it.getLong(idIndex) else -1L
                        val path = if (dataIndex >= 0) it.getString(dataIndex) ?: "" else ""
                        val date = if (dateIndex >= 0) it.getLong(dateIndex) * 1000L else 0L

                        if (date > newestTimestamp && date >= (recordedSinceTimestamp - 180000L)) {
                            newestTimestamp = date
                            latestFile = if (path.isNotEmpty()) File(path) else null
                            if (id >= 0) {
                                latestUri = android.content.ContentUris.withAppendedId(
                                    MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                                    id
                                )
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }

            // 3. Copy to Schat folder
            val timeStampStr = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
            val destFile = File(schatFolder, "Schat_ScreenRecord_$timeStampStr.mp4")

            var copied = false
            if (latestFile != null && latestFile.exists() && latestFile.canRead()) {
                try {
                    latestFile.copyTo(destFile, overwrite = true)
                    copied = destFile.exists() && destFile.length() > 0
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }

            if (!copied && latestUri != null) {
                try {
                    contentResolver.openInputStream(latestUri)?.use { input ->
                        destFile.outputStream().use { output ->
                            input.copyTo(output)
                        }
                    }
                    copied = destFile.exists() && destFile.length() > 0
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }

            if (copied) {
                MediaScannerConnection.scanFile(
                    applicationContext,
                    arrayOf(destFile.absolutePath),
                    arrayOf("video/mp4"),
                    null
                )
                return destFile.absolutePath
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return null
    }

    private fun saveScreenshotToStorage(bytes: ByteArray, requestedFileName: String?): String? {
        try {
            val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
            val fileName = requestedFileName ?: "Screenshot_$timeStamp.png"

            // 1. Android 10+ (API 29+): MediaStore insert into Pictures/Schat
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val contentValues = android.content.ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                    put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                    put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/Schat")
                    put(MediaStore.Images.Media.IS_PENDING, 1)
                }

                val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)
                if (uri != null) {
                    contentResolver.openOutputStream(uri)?.use { outputStream ->
                        outputStream.write(bytes)
                        outputStream.flush()
                    }
                    contentValues.clear()
                    contentValues.put(MediaStore.Images.Media.IS_PENDING, 0)
                    contentResolver.update(uri, contentValues, null, null)

                    val destPath = "/storage/emulated/0/Pictures/Schat/$fileName"
                    val destFile = File(destPath)
                    if (destFile.exists()) {
                        MediaScannerConnection.scanFile(
                            applicationContext,
                            arrayOf(destFile.absolutePath),
                            arrayOf("image/png"),
                            null
                        )
                    }

                    // Also save directly to Download/Schat so it appears under Downloads/Schat
                    try {
                        val downloadFolder = File("/storage/emulated/0/Download/Schat")
                        if (!downloadFolder.exists()) {
                            downloadFolder.mkdirs()
                        }
                        val downloadFile = File(downloadFolder, fileName)
                        downloadFile.outputStream().use { fos ->
                            fos.write(bytes)
                            fos.flush()
                        }
                        MediaScannerConnection.scanFile(
                            applicationContext,
                            arrayOf(downloadFile.absolutePath),
                            arrayOf("image/png"),
                            null
                        )
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }

                    return destPath
                }
            }

            // 2. Direct filesystem fallback for pre-Android 10 or if MediaStore fails
            val picturesFolder = File("/storage/emulated/0/Pictures/Schat")
            if (!picturesFolder.exists()) {
                picturesFolder.mkdirs()
            }
            val file = File(picturesFolder, fileName)
            file.outputStream().use { fos ->
                fos.write(bytes)
                fos.flush()
            }
            MediaScannerConnection.scanFile(
                applicationContext,
                arrayOf(file.absolutePath),
                arrayOf("image/png"),
                null
            )
            return file.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return null
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

        try {
            val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
            if (telephonyManager != null) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && telephonyCallback != null) {
                    telephonyManager.unregisterTelephonyCallback(telephonyCallback as android.telephony.TelephonyCallback)
                } else if (phoneStateListener != null) {
                    @Suppress("DEPRECATION")
                    telephonyManager.listen(phoneStateListener, android.telephony.PhoneStateListener.LISTEN_NONE)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        super.onDestroy()
    }
}
