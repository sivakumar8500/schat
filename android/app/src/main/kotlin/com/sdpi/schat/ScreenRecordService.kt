package com.sdpi.schat

import android.app.Activity
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.MediaRecorder
import android.media.MediaScannerConnection
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.MediaStore
import android.util.Log
import androidx.core.app.NotificationCompat
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class ScreenRecordService : Service() {

    companion object {
        const val TAG = "ScreenRecordService"
        const val NOTIFICATION_ID = 7891
        const val CHANNEL_ID = "schat_screen_record_channel"

        const val ACTION_START = "com.sdpi.schat.action.START_RECORD"
        const val ACTION_STOP = "com.sdpi.schat.action.STOP_RECORD"

        const val EXTRA_RESULT_CODE = "extra_result_code"
        const val EXTRA_DATA = "extra_data"
        const val EXTRA_WIDTH = "extra_width"
        const val EXTRA_HEIGHT = "extra_height"
        const val EXTRA_DPI = "extra_dpi"

        var isRecording = false
            private set

        var onRecordingStarted: (() -> Unit)? = null
        var onRecordingFailed: ((String) -> Unit)? = null
        private var pendingStopCallback: ((String?) -> Unit)? = null

        fun stopRecording(context: Context, callback: (String?) -> Unit) {
            if (!isRecording) {
                callback(null)
                return
            }
            pendingStopCallback = callback
            val stopIntent = Intent(context, ScreenRecordService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(stopIntent)
        }
    }

    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var mediaRecorder: MediaRecorder? = null
    private var tempOutputFile: File? = null
    private var recordStartTime = 0L
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) return START_NOT_STICKY

        when (intent.action) {
            ACTION_START -> {
                val notification = buildForegroundNotification()
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    startForeground(
                        NOTIFICATION_ID,
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
                    )
                } else {
                    startForeground(NOTIFICATION_ID, notification)
                }
                startRecordingInternal(intent)
            }
            ACTION_STOP -> {
                stopRecordingInternal()
            }
        }
        return START_NOT_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Screen Recording",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notification displayed while S-Chat records screen"
                setShowBadge(false)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            manager?.createNotificationChannel(channel)
        }
    }

    private fun buildForegroundNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("S-CHAT Screen Recording")
            .setContentText("Recording chat screen in progress...")
            .setSmallIcon(R.mipmap.launcher_icon)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun startRecordingInternal(intent: Intent) {
        val resultCode = intent.getIntExtra(EXTRA_RESULT_CODE, Activity.RESULT_CANCELED)
        val data = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(EXTRA_DATA, Intent::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(EXTRA_DATA)
        }

        if (resultCode != Activity.RESULT_OK || data == null) {
            Log.e(TAG, "Invalid result code or null intent data for media projection")
            onRecordingFailed?.invoke("Screen recording permission was not granted")
            stopSelf()
            return
        }

        var width = intent.getIntExtra(EXTRA_WIDTH, 1080)
        var height = intent.getIntExtra(EXTRA_HEIGHT, 1920)
        val dpi = intent.getIntExtra(EXTRA_DPI, 400)

        // Dimensions must be even for H.264 video encoding
        width = (width / 2) * 2
        height = (height / 2) * 2

        try {
            val mpManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            mediaProjection = mpManager.getMediaProjection(resultCode, data)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                mediaProjection?.registerCallback(object : MediaProjection.Callback() {
                    override fun onStop() {
                        Log.d(TAG, "MediaProjection stopped by system")
                    }
                }, mainHandler)
            }

            tempOutputFile = File(cacheDir, "temp_schat_record_${System.currentTimeMillis()}.mp4")

            @Suppress("DEPRECATION")
            mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(this)
            } else {
                MediaRecorder()
            }

            mediaRecorder?.apply {
                setVideoSource(MediaRecorder.VideoSource.SURFACE)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setVideoEncoder(MediaRecorder.VideoEncoder.H264)
                setVideoSize(width, height)
                setVideoFrameRate(30)
                setVideoEncodingBitRate(4_000_000)
                setOutputFile(tempOutputFile!!.absolutePath)
                prepare()
            }

            virtualDisplay = mediaProjection?.createVirtualDisplay(
                "SchatScreenRecord",
                width,
                height,
                dpi,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                mediaRecorder!!.surface,
                null,
                mainHandler
            )

            mediaRecorder?.start()
            recordStartTime = System.currentTimeMillis()
            isRecording = true
            Log.d(TAG, "Screen recording successfully started: ${width}x${height} -> ${tempOutputFile?.absolutePath}")

            onRecordingStarted?.invoke()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start MediaRecorder/MediaProjection: ${e.message}", e)
            isRecording = false
            cleanup()
            onRecordingFailed?.invoke(e.message ?: "Failed to start screen recording")
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
        }
    }

    private fun stopRecordingInternal() {
        if (!isRecording) {
            pendingStopCallback?.invoke(null)
            pendingStopCallback = null
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return
        }

        isRecording = false

        // MediaRecorder requires at least ~1 second of frames before calling stop()
        val elapsed = System.currentTimeMillis() - recordStartTime
        val delay = if (elapsed < 1200L) (1200L - elapsed) else 0L

        mainHandler.postDelayed({
            try {
                try {
                    mediaRecorder?.stop()
                } catch (e: Exception) {
                    Log.w(TAG, "MediaRecorder.stop() exception: ${e.message}")
                }
                cleanup()

                var savedPath: String? = null
                val file = tempOutputFile
                if (file != null && file.exists() && file.length() > 5000L) {
                    savedPath = saveFileToSchat(file)
                    Log.d(TAG, "Saved screen recording to: $savedPath (${file.length()} bytes)")
                } else {
                    Log.w(TAG, "Temporary recording file is empty or missing: ${file?.length()} bytes")
                    file?.delete()
                }

                pendingStopCallback?.invoke(savedPath)
                pendingStopCallback = null
            } catch (e: Exception) {
                Log.e(TAG, "Error in stopRecordingInternal: ${e.message}", e)
                pendingStopCallback?.invoke(null)
                pendingStopCallback = null
            } finally {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }, delay)
    }

    private fun saveFileToSchat(tempFile: File): String? {
        val timeStampStr = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
        val fileName = "Schat_ScreenRecord_$timeStampStr.mp4"
        var savedPath: String? = null

        val downloadDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        val schatFolder = File(downloadDir, "Schat")
        try {
            if (!schatFolder.exists()) {
                schatFolder.mkdirs()
            }
        } catch (e: Exception) {
            Log.w(TAG, "Could not mkdirs on schatFolder: ${e.message}")
        }

        // 1. Android 10+ Scoped Storage via MediaStore.Downloads
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val contentValues = ContentValues().apply {
                    put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                    put(MediaStore.Downloads.MIME_TYPE, "video/mp4")
                    put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/Schat/")
                    put(MediaStore.Downloads.IS_PENDING, 1)
                }
                val destUri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
                if (destUri != null) {
                    contentResolver.openOutputStream(destUri)?.use { outStream ->
                        tempFile.inputStream().use { inpStream ->
                            inpStream.copyTo(outStream)
                        }
                        outStream.flush()
                    }
                    contentValues.clear()
                    contentValues.put(MediaStore.Downloads.IS_PENDING, 0)
                    contentResolver.update(destUri, contentValues, null, null)

                    try {
                        contentResolver.query(destUri, arrayOf(MediaStore.MediaColumns.DATA), null, null, null)?.use { cursor ->
                            if (cursor.moveToFirst()) {
                                val idx = cursor.getColumnIndex(MediaStore.MediaColumns.DATA)
                                if (idx >= 0) {
                                    val actualPath = cursor.getString(idx)
                                    if (!actualPath.isNullOrEmpty() && File(actualPath).exists()) {
                                        savedPath = actualPath
                                    }
                                }
                            }
                        }
                    } catch (e: Exception) {
                        Log.w(TAG, "Query DATA from destUri error: ${e.message}")
                    }

                    if (savedPath == null) {
                        savedPath = File(schatFolder, fileName).absolutePath
                    }
                    Log.d(TAG, "Inserted into MediaStore.Downloads: $savedPath")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error saving via MediaStore.Downloads: ${e.message}")
            }
        }

        // 2. Fallback to direct file write
        if (savedPath == null || !File(savedPath).exists() || File(savedPath).length() < 1000L) {
            try {
                val destFile = File(schatFolder, fileName)
                tempFile.copyTo(destFile, overwrite = true)
                if (destFile.exists() && destFile.length() > 0) {
                    savedPath = destFile.absolutePath
                    Log.d(TAG, "Saved via direct file write: $savedPath")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error saving via direct file: ${e.message}")
            }
        }

        // 3. Scan with MediaStore so it appears immediately in Gallery and file pickers
        if (savedPath != null && File(savedPath).exists()) {
            MediaScannerConnection.scanFile(
                applicationContext,
                arrayOf(savedPath),
                arrayOf("video/mp4")
            ) { path, uri ->
                Log.d(TAG, "MediaScanner indexed: $path -> $uri")
            }
        }

        try {
            tempFile.delete()
        } catch (e: Exception) {}

        return savedPath
    }

    private fun cleanup() {
        try {
            mediaRecorder?.reset()
            mediaRecorder?.release()
        } catch (e: Exception) {}
        mediaRecorder = null

        try {
            virtualDisplay?.release()
        } catch (e: Exception) {}
        virtualDisplay = null

        try {
            mediaProjection?.stop()
        } catch (e: Exception) {}
        mediaProjection = null
    }

    override fun onDestroy() {
        cleanup()
        isRecording = false
        super.onDestroy()
    }
}
