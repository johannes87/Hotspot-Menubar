package com.gmail.bittner.johannes.tetheringhelper.service

import android.content.Context
import android.os.Build
import android.telephony.TelephonyCallback
import android.telephony.TelephonyDisplayInfo
import android.telephony.TelephonyManager
import android.util.Log
import androidx.annotation.RequiresApi
import kotlinx.coroutines.*
import java.io.PrintWriter
import java.net.ServerSocket
import java.net.Socket
import java.net.SocketException
import java.util.concurrent.Executors

private const val TAG = "SignalSender"

/**
 * SignalSender sends the current signal type and quality to connecting clients.
 * It is also responsible for publishing and unpublishing a Bonjour service.
 */
class SignalSender(private val phoneName: String, private val context: Context) {
    private val coroutineScope = CoroutineScope(Job() + Dispatchers.IO)

    private lateinit var serverSocket: ServerSocket
    private lateinit var bonjourPublisher: BonjourPublisher
    private lateinit var telephonyManager: TelephonyManager

    private var serverLoopJob: Job? = null
    private var isRunning = false

    private var android12AndUpCallback: TelephonyCallback? = null
    @Suppress("DEPRECATION")
    private var android11Callback: android.telephony.PhoneStateListener? = null
    private var telephonyDisplayInfo: TelephonyDisplayInfo? = null

    fun start() {
        if (isRunning) {
            return
        }
        isRunning = true

        serverSocket = ServerSocket(0)
        bonjourPublisher = BonjourPublisher(
            serviceName = phoneName,
            context = context,
            port = serverSocket.localPort
        )
        bonjourPublisher.publish()

        telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            setup5GDetectionForAndroid12AndUp()
        } else if (Build.VERSION.SDK_INT == Build.VERSION_CODES.R) {
            setup5GDetectionForAndroid11()
        }

        Log.d(TAG, "Starting with port=${serverSocket.localPort}")
        serverLoopJob = coroutineScope.launch {
            serverLoop()
        }

        // TODO: get wifi lock: https://developer.android.com/reference/android/net/wifi/WifiManager.WifiLock.html
        // maybe wifi lock is not necessary, test this. hotspot might keep wifi active anyway
        // TODO: request disabling auto-reset of permissions
    }

    fun stop() {
        if (!isRunning) {
            return
        }
        Log.d(TAG, "Stopping")
        isRunning = false
        serverLoopJob?.cancel()
        bonjourPublisher.unpublish()
        if (!serverSocket.isClosed) {
            serverSocket.close()
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            teardown5GDetectionForAndroid12AndUp()
        } else if (Build.VERSION.SDK_INT == Build.VERSION_CODES.R) {
            teardown5GDetectionForAndroid11()
        }
    }

    private suspend fun serverLoop() {
        // runInterruptible is needed so the coroutine can be cancelled while in serverSocket.accept()
        runInterruptible {
            while (true) {
                Log.d(TAG, "serverLoop is waiting for connection")
                var clientSocket: Socket?
                try {
                    clientSocket = serverSocket.accept()
                } catch (e: SocketException) {
                    // Exception is expected. Happens when stop() closes serverSocket while accept()'ing
                    return@runInterruptible
                }

                // Hooray, send out the phone signal.
                sendPhoneSignal(clientSocket)
            }
        }
    }

    private fun sendPhoneSignal(clientSocket: Socket) {
        val output = PrintWriter(clientSocket.getOutputStream(), true)
        val phoneSignal = PhoneSignal.getSignal(telephonyManager, telephonyDisplayInfo)
        Log.d(TAG, "Sending phone signal: quality=${phoneSignal.quality} type=${phoneSignal.type}")
        output.println(phoneSignal.toJSON())
        clientSocket.close()
    }

    @RequiresApi(Build.VERSION_CODES.S)
    /** The setup5GDetection* functions are necessary to get TelephonyDisplayInfo, which is needed
     * to detect if we're on non-standalone 5G.
     */
    private fun setup5GDetectionForAndroid12AndUp() {
        android12AndUpCallback = object : TelephonyCallback(), TelephonyCallback.DisplayInfoListener {
            override fun onDisplayInfoChanged(telephonyDisplayInfo: TelephonyDisplayInfo) {
                this@SignalSender.telephonyDisplayInfo = telephonyDisplayInfo
            }
        }

        android12AndUpCallback?.let { callback ->
            telephonyManager.registerTelephonyCallback(
                Executors.newSingleThreadExecutor(),
                callback)
        }
    }

    @RequiresApi(Build.VERSION_CODES.S)
    private fun teardown5GDetectionForAndroid12AndUp() {
        android12AndUpCallback?.let { callback -> telephonyManager.unregisterTelephonyCallback(callback) }
    }

    @RequiresApi(Build.VERSION_CODES.R)
    @Suppress("DEPRECATION")
    /**
     * We need the setup/teardown Android11 functions to detect non-standalone 5G on Android 11,
     * so we need to use deprecated code.
     * */
    private fun setup5GDetectionForAndroid11() {
        android11Callback = object : android.telephony.PhoneStateListener() {
            override fun onDisplayInfoChanged(telephonyDisplayInfo: TelephonyDisplayInfo) {
                try {
                    super.onDisplayInfoChanged(telephonyDisplayInfo)
                } catch (e: SecurityException) {
                    Log.e(
                        TAG,
                        "Required permissions missing. This should never happen, please report a bug."
                    )
                    throw e
                }
                this@SignalSender.telephonyDisplayInfo = telephonyDisplayInfo
            }
        }
        telephonyManager.listen(
            android11Callback,
            android.telephony.PhoneStateListener.LISTEN_DISPLAY_INFO_CHANGED
        )
    }

    @RequiresApi(Build.VERSION_CODES.R)
    @Suppress("DEPRECATION")
    private fun teardown5GDetectionForAndroid11() {
        android11Callback?.let { callback ->
            telephonyManager.listen(
                callback,
                android.telephony.PhoneStateListener.LISTEN_NONE
            )
        }
    }
}
