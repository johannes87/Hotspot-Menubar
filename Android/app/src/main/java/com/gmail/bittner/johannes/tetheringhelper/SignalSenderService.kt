package com.gmail.bittner.johannes.tetheringhelper

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.IBinder
import androidx.preference.PreferenceManager
import com.gmail.bittner.johannes.tetheringhelper.ui.MainActivity

/**
 * SignalSenderService is a long-running background service that contains SignalSender.
 * This is needed so that SignalSender keeps running even if the Activity is closed.
 *
 * @see https://robertohuertas.com/2019/06/29/android_foreground_services/
 */
class SignalSenderService : Service() {
    private var isRunning = false
    private lateinit var signalSender: SignalSender
    private lateinit var sharedPreferences: SharedPreferences

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (isRunning) {
            return super.onStartCommand(intent, flags, startId)
        }

        super.onStartCommand(intent, flags, startId)
        isRunning = true
        signalSender.start()
        return START_STICKY
    }

    override fun onCreate() {
        super.onCreate()
        sharedPreferences = PreferenceManager.getDefaultSharedPreferences(this)
        signalSender = SignalSender(
            sharedPreferences.getString(SharedPreferencesKeys.phoneName, "")!!,
            this)
        startForeground(1, createNotification())
    }

    /**
     * Creates a notification necessary for a long-running service
     *
     * @see https://robertohuertas.com/2019/06/29/android_foreground_services/
     */
    private fun createNotification(): Notification {
        val notificationChannelId = "NOTIFICATION_CHANNEL_TETHERING_HELPER_ACTIVE"

        // depending on the Android API that we're dealing with we will have
        // to use a specific method to create the notification

        // Leave this check for now, minSdkVersion might be lowered later
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationChannelName = getString(R.string.service_notification_channel_name)

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = NotificationChannel(
                notificationChannelId,
                notificationChannelName,
                NotificationManager.IMPORTANCE_HIGH
            ).let {
                it.enableLights(false)
                it.enableVibration(false)
                it
            }
            notificationManager.createNotificationChannel(channel)
        }

        val pendingIntent: PendingIntent = Intent(this, MainActivity::class.java).let { notificationIntent ->
            PendingIntent.getActivity(this, 0, notificationIntent, 0)
        }

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) Notification.Builder(
            this,
            notificationChannelId
        ) else Notification.Builder(this)

        // Not sure why setPriority is necessary. Tested with Android API25
        // Service was still running in background without setPriority call
        // Service also continues to run when closing app in app switcher
        return builder
            .setContentTitle(getString(R.string.service_notification_content_title))
            .setContentText(getString(R.string.service_notification_content_text))
            .setContentIntent(pendingIntent)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setTicker(getString(R.string.service_notification_ticker_text))
            .setPriority(Notification.PRIORITY_HIGH) // for under android 26 compatibility
            .build()
    }
}