package com.sdpi.schat

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import io.flutter.app.FlutterApplication

class MainApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java) ?: return

            val defaultRingtoneUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                .build()

            // 1. Primary Call Notification Channel
            val callChannel = NotificationChannel(
                "schat_calls_channel_v5",
                "Incoming Calls",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Incoming video and audio calls with Decline and Accept actions"
                setSound(defaultRingtoneUri, audioAttributes)
                enableVibration(true)
                setShowBadge(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }

            // 2. CallKit Default Channel fallback
            val callkitChannel = NotificationChannel(
                "callkit_incoming_channel_id",
                "Incoming Calls",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Incoming call notifications"
                setSound(defaultRingtoneUri, audioAttributes)
                enableVibration(true)
                setShowBadge(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }

            // 3. Name-based channel fallback
            val nameChannel = NotificationChannel(
                "Incoming Calls",
                "Incoming Calls",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Incoming call alerts"
                setSound(defaultRingtoneUri, audioAttributes)
                enableVibration(true)
                setShowBadge(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }

            // 4. CallKit Ongoing Call Channel
            val ongoingChannel = NotificationChannel(
                "callkit_ongoing_channel_id",
                "Ongoing Calls",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Ongoing active call notification"
                enableVibration(false)
                setShowBadge(false)
            }

            // 5. CallKit Missed Call Channel
            val missedChannel = NotificationChannel(
                "callkit_missed_channel_id",
                "Missed Calls",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Missed call alerts"
                enableVibration(true)
                setShowBadge(true)
            }

            // 6. General Notifications Channel
            val generalChannel = NotificationChannel(
                "schat_general_channel",
                "General Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for chats and other alerts"
                enableVibration(true)
                setShowBadge(true)
            }

            notificationManager.createNotificationChannel(callChannel)
            notificationManager.createNotificationChannel(callkitChannel)
            notificationManager.createNotificationChannel(nameChannel)
            notificationManager.createNotificationChannel(ongoingChannel)
            notificationManager.createNotificationChannel(missedChannel)
            notificationManager.createNotificationChannel(generalChannel)
        }
    }
}
