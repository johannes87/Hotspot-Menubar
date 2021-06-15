package com.gmail.bittner.johannes.tetheringhelper

import android.content.Context
import android.telephony.TelephonyManager
import android.util.Log
import kotlinx.coroutines.*
import java.io.PrintWriter
import java.net.ServerSocket
import java.net.Socket
import java.net.SocketException

/**
 * SignalSender sends the current signal type and quality to connecting clients.
 * It is also responsible for publishing and unpublishing a Bonjour service.
 */
class SignalSender(private val phoneName: String, private val context: Context) {
    private val TAG = "SignalSender"
    private val coroutineScope = CoroutineScope(Job() + Dispatchers.IO)

    private lateinit var serverSocket: ServerSocket
    private lateinit var bonjourPublisher: BonjourPublisher

    private var serverLoopJob: Job? = null
    private var isRunning = false

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
    }

    private suspend fun serverLoop() {
        val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

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
                sendPhoneSignal(clientSocket, telephonyManager)
            }
        }
    }

    private fun sendPhoneSignal(
        clientSocket: Socket,
        telephonyManager: TelephonyManager
    ) {
        val output = PrintWriter(clientSocket.getOutputStream(), true)
        val phoneSignal = PhoneSignal.getSignal(telephonyManager)
        Log.d(TAG, "Sending phone signal: quality=${phoneSignal.quality} type=${phoneSignal.type}")
        output.println(phoneSignal.toJSON())
        clientSocket.close()
    }
}