package com.gmail.bittner.johannes.tetheringhelper


import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {
    private val TAG = MainActivity::class.qualifiedName
    private lateinit var signalSender: SignalSender

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        signalSender = SignalSender(
            phoneName = "Sony Xperia XZ1 Compact",
            context = this
        )
        signalSender.start()
    }
}