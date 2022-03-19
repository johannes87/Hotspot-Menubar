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
import java.net.InetSocketAddress

private const val TAG = "SignalSender"

/**
 * SignalSender sends the current signal type and quality to connecting clients.
 * It is also responsible for publishing and unpublishing a Bonjour service.
 */
class SignalSender(private val phoneName: String, private val context: Context) {
    private val coroutineScope = CoroutineScope(Job() + Dispatchers.IO)
    private val hotspotInterfaceIPv4 = HotspotInterfaceIPv4(context)

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
        val hotspotInterfaceIPv4 = hotspotInterfaceIPv4.getHotspotIPv4Address() ?: run {
            Log.d(TAG, "Couldn't get IPv4 of hotspot interface, not starting sender")
            return
        }
        Log.d(TAG, "Found hotspot IPv4: $hotspotInterfaceIPv4")

        isRunning = true

        telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

        serverSocket = ServerSocket()
        serverSocket.bind(InetSocketAddress(hotspotInterfaceIPv4, 0))

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
