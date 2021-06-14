package com.gmail.bittner.johannes.tetheringhelper

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.IBinder
import androidx.core.app.NotificationCompat
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

        setupForegroundService()
    }

    /**
     * Creates a notification that necessary for a long-running service and starts the
     * service in foreground with this notification.
     *
     * @see https://robertohuertas.com/2019/06/29/android_foreground_services/
     */
    private fun setupForegroundService() {
        val notificationChannelId = "NOTIFICATION_CHANNEL_TETHERING_HELPER_ACTIVE"
        val notificationId = 1

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            notificationChannelId,
            getString(R.string.service_notification_channel_name),
            NotificationManager.IMPORTANCE_MIN
        ).let {
            it.enableLights(false)
            it.enableVibration(false)
            it.setSound(null, null)
            it.setShowBadge(false)
            it
        }
        notificationManager.createNotificationChannel(channel)

        val contentIntent = Intent(this, MainActivity::class.java).let { intent ->
            PendingIntent.getActivity(this, 0, intent, 0)
        }

        val builder = NotificationCompat.Builder(this, notificationChannelId)

        val notification = builder
            .setContentTitle(getString(R.string.service_notification_tetherhinghelper_is_running))
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setContentIntent(contentIntent)
            .build()

        startForeground(notificationId, notification)
    }
}