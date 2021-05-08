package com.gmail.bittner.johannes.tetheringhelper

import android.content.Context
import java.io.PrintWriter
import java.net.ServerSocket
import kotlin.concurrent.thread

/**
 * This class sends the current signal type and quality to connecting clients.
 */
class SignalSender(phoneName: String, context: Context) {
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

        thread(start = true) {
            while (true) {
                val clientSocket = serverSocket.accept()
                val output = PrintWriter(clientSocket.getOutputStream(), true)

                val randomAnswers = arrayOf(
                    "{\"quality\": 4, \"type\": \"2G\"}",
                    "{\"quality\": 1, \"type\": \"3G\"}",
                    "{\"quality\": 2, \"type\": \"LTE\"}",
                    "{\"quality\": 3, \"type\": \"E\"}",
                    "{\"quality\": 2, \"type\": \"LTE\"}",
                    "{\"quality\": 1, \"type\": \"H\"}"
                )

                output.println(randomAnswers.random())
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