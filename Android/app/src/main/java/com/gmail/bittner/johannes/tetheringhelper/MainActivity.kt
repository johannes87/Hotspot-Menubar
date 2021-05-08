package com.gmail.bittner.johannes.tetheringhelper


import android.Manifest
import android.os.Bundle
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import kotlinx.android.synthetic.main.activity_main.*

// TODO: make it possible to connect to service when phone is in standby mode
// TODO: stop broadcasting service when app is swiped-away in android task manager

class MainActivity : AppCompatActivity() {
    private lateinit var signalSender: SignalSender

    // TODO use permission request activity with explanation
    // TODO handle no permission granted case
    private fun requestRuntimePermissions() {
        val runtimePermissions = arrayOf(Manifest.permission.READ_PHONE_STATE)

        val requestMultiplePermissions = registerForActivityResult(
            ActivityResultContracts.RequestMultiplePermissions()
        ) {}

        requestMultiplePermissions.launch(runtimePermissions)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        requestRuntimePermissions()

        signalSender = SignalSender(
            phoneName = "Sony Xperia XZ1 Compact",
            context = this
        )
        signalSender.start()

        networkPortTextView.text = signalSender.listenPort.toString()
    }
}