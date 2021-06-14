package com.gmail.bittner.johannes.tetheringhelper

import android.content.Context
import android.telephony.TelephonyManager
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import java.io.PrintWriter
import java.net.ServerSocket

/**
 * This class sends the current signal type and quality to connecting clients.
 */
class SignalSender(phoneName: String, val context: Context) {
    private val bonjourPublisher: BonjourPublisher
    // A port number of 0 means that the port number is automatically allocated
    private val serverSocket: ServerSocket = ServerSocket(0)
    private val coroutineScope = CoroutineScope(Job() + Dispatchers.IO)

    init {
        bonjourPublisher = BonjourPublisher(
            serviceName = phoneName,
            port = serverSocket.localPort,
            context = context
        )
    }

    fun start() {
        bonjourPublisher.publish()

        // TODO: get wifi lock: https://developer.android.com/reference/android/net/wifi/WifiManager.WifiLock.html
        // TODO: request disabling auto-reset of permissions


        coroutineScope.launch { serverLoop() }
    }

    fun stop() {
        bonjourPublisher.unpublish()
    }

    private fun serverLoop() {
        val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        val wifiManager = context.getSystemService(Context.WIFI_SERVICE) as WifiManager

        while (true) {
            val clientSocket = serverSocket.accept()
            val output = PrintWriter(clientSocket.getOutputStream(), true)
            val phoneSignal = PhoneSignal.getSignal(telephonyManager)
            output.println(phoneSignal.toJSON())
            clientSocket.close()
        }
    }
}