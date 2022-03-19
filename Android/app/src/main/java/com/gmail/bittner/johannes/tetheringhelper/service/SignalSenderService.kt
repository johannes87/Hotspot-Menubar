package com.gmail.bittner.johannes.tetheringhelper.service

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.*
import android.net.wifi.WifiManager
import android.os.Binder
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.preference.PreferenceManager
import com.gmail.bittner.johannes.tetheringhelper.R
import com.gmail.bittner.johannes.tetheringhelper.ui.MainActivity
import com.gmail.bittner.johannes.tetheringhelper.utils.SharedPreferencesKeys
import kotlinx.coroutines.*

private const val TAG = "SignalSenderService"

/**
 * SignalSenderServiceBinder is needed for communication between Service and Activity
 */
class SignalSenderServiceBinder(val service: SignalSenderService) : Binder()

/**
 * SignalSenderStatus is used to communicate the activity status of SignalSender
 */
enum class SignalSenderStatus {
    /**
     * INACTIVE means SignalSender is not sending its status because the
     * run conditions are not fulfilled (e.g. hotspot is not active)
     */
    INACTIVE,

    /** ACTIVE means that SignalSender is sending its status when connected */
    ACTIVE
}

/**
 * SignalSenderService is a long-running background service that contains SignalSender.
 * This is needed so that SignalSender keeps running even if the Activity is closed.
 *
 * @see https://robertohuertas.com/2019/06/29/android_foreground_services/
 */
class SignalSenderService : Service() {
    private val mainCoroutineScope = CoroutineScope(Job() + Dispatchers.Main)

    /**
     * Used by other components to get the signalSenderStatus
     */
    var signalSenderStatus: SignalSenderStatus = SignalSenderStatus.INACTIVE
        private set
    /**
     * statusUpdateCallback will be set by connecting components who want to receive status updates
     */
    var statusUpdateCallback: ((status: SignalSenderStatus) -> Unit)? = null

    private lateinit var signalSender: SignalSender
    private lateinit var sharedPreferences: SharedPreferences
    private lateinit var hotspotStateReceiver: BroadcastReceiver

    private var isRunning = false

    override fun onBind(intent: Intent?): IBinder {
        return SignalSenderServiceBinder(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // There's no way in Android >= O to check if the service is running before starting
        // see the comments in this answer: https://stackoverflow.com/a/5921190/96205
        Log.d(TAG, "onStartCommand: isRunning=$isRunning")
        if (isRunning) {
            Log.d(TAG, "onStartCommand: not starting, as service is already running")
            return super.onStartCommand(intent, flags, startId)
        }
        isRunning = true

        sharedPreferences = PreferenceManager.getDefaultSharedPreferences(this)
        signalSender = SignalSender(
            sharedPreferences.getString(SharedPreferencesKeys.phoneName, "")!!,
            this
        )

        createHotspotStateListener()

        if (isWifiHotspotActive()) {
            // startSignalSender creates the foreground notification
            startSignalSender()
        } else {
            Log.d(TAG, "Wifi hotspot not active, not starting SignalSender")
            createForegroundNotification()
        }

        super.onStartCommand(intent, flags, startId)
        return START_STICKY
    }

    override fun onDestroy() {
        Log.d(TAG, "onDestroy")
        super.onDestroy()
        stopSignalSender()
        stopForeground(true)
        unregisterReceiver(hotspotStateReceiver)
    }

    private fun startSignalSender() {
        signalSender.start()
        signalSenderStatus = SignalSenderStatus.ACTIVE
        createForegroundNotification()
        statusUpdateCallback?.let { it(signalSenderStatus) }
    }

    private fun stopSignalSender() {
        signalSender.stop()
        signalSenderStatus = SignalSenderStatus.INACTIVE
        createForegroundNotification()
        statusUpdateCallback?.let { it(signalSenderStatus) }
    }

    /**
     * Creates a notification that's necessary for a long-running service and starts the
     * service in foreground with this notification.
     *
     * @see https://robertohuertas.com/2019/06/29/android_foreground_services/
     */
    private fun createForegroundNotification() {
        val notificationChannelId = "NOTIFICATION_CHANNEL_TETHERING_HELPER_STATUS"
        val notificationId = 1

        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

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
            PendingIntent.getActivity(
                this,
                0,
                intent,
                PendingIntent.FLAG_IMMUTABLE
            )
        }

        val builder = NotificationCompat.Builder(this, notificationChannelId)

        val notificationText = when (signalSenderStatus) {
            SignalSenderStatus.INACTIVE ->
                getString(R.string.service_notification_tetheringhelper_is_inactive)
            SignalSenderStatus.ACTIVE ->
                getString(R.string.service_notification_tetheringhelper_is_running)
        }

        val notification = builder
            .setContentTitle(notificationText)
            .setSmallIcon(R.drawable.ic_notification)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setContentIntent(contentIntent)
            .build()

        startForeground(notificationId, notification)
    }

    /**
     * The BroadcastReceiver utilised in createHotspotStateListener is needed to start and stop
     * the SignalSender when the hotspot gets inactive/active
     *
     * @see https://stackoverflow.com/a/36162745/96205
     */
    private fun createHotspotStateListener() {
        hotspotStateReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val extra = intent?.getIntExtra(WifiManager.EXTRA_WIFI_STATE, 0) ?: return
                val wifiState = extra % 10
                if (wifiState == WifiManager.WIFI_STATE_ENABLED) {
                    Log.d(TAG, "Hotspot state changed: enabled")
                    // Dispatchers.Main used because FiveGDetection (used during start) fails
                    // if not run on main thread (when creating PhoneStateListener)
                    mainCoroutineScope.launch {
                        // needed because it takes some time for hotspot interface to come up,
                        // which is necessary to determine the interface IPv4 address
                        delay(500)
                        startSignalSender()
                    }
                } else if (wifiState == WifiManager.WIFI_STATE_DISABLED) {
                    Log.d(TAG, "Hotspot state changed: disabled")
                    stopSignalSender()
                }
            }
        }

        registerReceiver(
            hotspotStateReceiver,
            IntentFilter("android.net.wifi.WIFI_AP_STATE_CHANGED")
        )
    }

    /**
     * Detects if the WiFi hotspot is active on the phone.
     *
     * Some reflection is needed for this.
     * @see https://developer.android.com/guide/app-compatibility/restrictions-non-sdk-interfaces
     * It is listed as "whitelist" in Android 11's "hiddenapi-flags.csv", so it should be safe to use
     */
    private fun isWifiHotspotActive(): Boolean {
        val wifiManager = getSystemService(WIFI_SERVICE) as WifiManager
        val method = wifiManager.javaClass.getDeclaredMethod("isWifiApEnabled")
        method.isAccessible = true
        return method.invoke(wifiManager) as Boolean
    }
}
