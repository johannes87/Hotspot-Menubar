package com.gmail.bittner.johannes.tetheringhelper

import android.content.Context
import android.telephony.TelephonyManager
import android.util.Log
import java.io.PrintWriter
import java.net.ServerSocket
import kotlin.concurrent.thread

/**
 * This class sends the current signal type and quality to connecting clients.
 */
class SignalSender(phoneName: String, val context: Context) {
    private val bonjourPublisher: BonjourPublisher
    // A port number of 0 means that the port number is automatically allocated
    private val serverSocket: ServerSocket = ServerSocket(0)

    init {
        bonjourPublisher = BonjourPublisher(
            serviceName = phoneName,
            port = serverSocket.localPort,
            context = context
        )
    }

    fun start() {
        bonjourPublisher.publish()

        // TODO: use coroutines, easier to cancel
        // https://kotlinlang.org/docs/reference/coroutines/basics.html
        // https://kotlinlang.org/docs/reference/coroutines/cancellation-and-timeouts.html

        // probably: use either launch or GlobalScope.launch

        // TODO: get wifi lock: https://developer.android.com/reference/android/net/wifi/WifiManager.WifiLock.html
        // TODO: request disabling auto-reset of permissions

        val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

        thread(start = true) {
            while (true) {
                val clientSocket = serverSocket.accept()
                val output = PrintWriter(clientSocket.getOutputStream(), true)
                val phoneSignal = PhoneSignal.getSignal(telephonyManager)
                output.println(phoneSignal.toJSON())
                clientSocket.close()
            }
        }
    }

    val listenPort: Int
        get() = serverSocket.localPort

    fun stop() {
        bonjourPublisher.unpublish()
    }
}