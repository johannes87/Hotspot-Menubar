package com.gmail.bittner.johannes.tetheringhelper.service

import android.content.Context
import android.os.Build
import android.telephony.TelephonyManager
import android.util.Log
import java.io.PrintWriter
import java.net.ServerSocket
import java.net.Socket
import java.net.SocketException
import kotlinx.coroutines.*

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

    private var fiveGDetection: FiveGDetection? = null
    private var serverLoopJob: Job? = null
    private var isRunning = false

    fun start() {
        if (isRunning) {
            return
        }
        isRunning = true

        telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

        serverSocket = ServerSocket(0)
        bonjourPublisher = BonjourPublisher(
            serviceName = phoneName,
            context = context,
            port = serverSocket.localPort
        )
        bonjourPublisher.publish()

        // Avoid NoClassDefFoundError on older Android versions
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            fiveGDetection = FiveGDetection(telephonyManager)
        }

        Log.d(TAG, "Starting with port=${serverSocket.localPort}")
        serverLoopJob = coroutineScope.launch {
            serverLoop()
        }
    }

    fun stop() {
        if (!isRunning) {
            return
        }
        isRunning = false

        Log.d(TAG, "Stopping")
        serverLoopJob?.cancel()
        bonjourPublisher.unpublish()
        fiveGDetection?.teardown()

        if (!serverSocket.isClosed) {
            serverSocket.close()
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
        val phoneSignal = PhoneSignal.getSignal(
            telephonyManager,
            fiveGDetection?.telephonyDisplayInfo
        )
        Log.d(TAG, "Sending phone signal: quality=${phoneSignal.quality} type=${phoneSignal.type}")
        output.println(phoneSignal.toJSON())
        clientSocket.close()
    }
}
