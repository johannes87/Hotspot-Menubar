package com.gmail.bittner.johannes.tetheringhelper.ui

import android.content.ComponentName
import android.content.Intent
import android.content.ServiceConnection
import android.content.SharedPreferences
import android.os.Bundle
import android.os.IBinder
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import androidx.databinding.DataBindingUtil
import androidx.preference.PreferenceManager
import com.gmail.bittner.johannes.tetheringhelper.R
import com.gmail.bittner.johannes.tetheringhelper.SharedPreferencesKeys
import com.gmail.bittner.johannes.tetheringhelper.databinding.ActivityMainBinding
import com.gmail.bittner.johannes.tetheringhelper.service.RunConditionMonitor
import com.gmail.bittner.johannes.tetheringhelper.service.SignalSenderService
import com.gmail.bittner.johannes.tetheringhelper.service.SignalSenderServiceBinder
import com.gmail.bittner.johannes.tetheringhelper.service.SignalSenderStatus
import com.gmail.bittner.johannes.tetheringhelper.utils.Permissions

/**
 * TetheringHelperStatus encapsulates the status of the whole Android app that is
 * shown to the user.
 */
private enum class TetheringHelperStatus {
    /** DISABLED means TetheringHelper is disabled in the settings */
    DISABLED,
    /** INACTIVE corresponds to SignalSenderStatus.INACTIVE
     * @see SignalSenderStatus.INACTIVE */
    INACTIVE,
    /** ACTIVE corresponds to SignalSenderStatus.ACTIVE
     * @see SignalSenderStatus.ACTIVE */
    ACTIVE
}

private const val TAG = "MainActivity"

class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding
    private lateinit var sharedPreferences: SharedPreferences
    private lateinit var runConditionMonitor: RunConditionMonitor
    private var signalSenderService: SignalSenderService? = null
    private val tetheringHelperEnabled: Boolean
        get() = sharedPreferences.getBoolean(SharedPreferencesKeys.tetheringHelperEnabled, false)

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            Log.d(TAG,"Service connected")
            signalSenderService = (service as? SignalSenderServiceBinder)?.service
            this@MainActivity.onServiceConnected()
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            Log.d(TAG,"Service disconnected")
            signalSenderService = null
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        Log.d(TAG, "onCreate")
        super.onCreate(savedInstanceState)
        binding = DataBindingUtil.setContentView(this, R.layout.activity_main)
        sharedPreferences = PreferenceManager.getDefaultSharedPreferences(this)
        runConditionMonitor = RunConditionMonitor(this)
        lifecycle.addObserver(runConditionMonitor)

        if (maybeStartFirstTimeSetup()) {
            return
        }

        binding.buttonSettings.setOnClickListener {
            startActivity(Intent(this, SettingsActivity::class.java))
        }
    }

    override fun onResume() {
        Log.d(TAG, "onResume")
        super.onResume()

        if (tetheringHelperEnabled && signalSenderService == null) {
            Intent(this, SignalSenderService::class.java).also { intent ->
                bindService(intent, serviceConnection, 0)
            }
        }
        if (!tetheringHelperEnabled) {
            showTetheringHelperStatus(TetheringHelperStatus.DISABLED)
        }
    }

    override fun onPause() {
        Log.d(TAG, "onPause")
        super.onPause()
        if (signalSenderService != null) {
            unbindService(serviceConnection)
            signalSenderService = null
        }
    }

    /**
     * onServiceConnected is called by serviceConnection when the Service is connected.
     * Extracted to this function to keep serviceConnection small
     */
    private fun onServiceConnected() {
        // We use !! because onServiceConnected is called after signalSenderService is set
        // I.e., it should never happen that it is null, and we want to be informed if it is
        signalSenderService!!.statusUpdateCallback = { status ->
            onSignalSenderStatusChanged(status)
        }

        // Sometimes the first SignalSenderStatusChanged happens before the service is connected
        // Therefore, explicitly request the status when connected
        showTetheringHelperStatus(getTetheringHelperStatus(signalSenderService!!.signalSenderStatus))
    }

    /**
     * onSignalSenderStatusChanged is needed so that the activity can be informed about
     * status changes of SignalSender.
     */
    private fun onSignalSenderStatusChanged(signalSenderStatus: SignalSenderStatus) {
        Log.d(TAG, "SignalSenderStatus changed: $signalSenderStatus")
        showTetheringHelperStatus(getTetheringHelperStatus(signalSenderStatus))
    }

    /**
     * Encapsulate the UI changes that happen when TetheringHelperStatus changes
     */
    private fun showTetheringHelperStatus(tetheringHelperStatus: TetheringHelperStatus) {
        binding.textViewStatus.text = "$tetheringHelperStatus"
    }

    /**
     * Handy function that gets the TetheringHelperStatus
     */
    private fun getTetheringHelperStatus(signalSenderStatus: SignalSenderStatus): TetheringHelperStatus {
        if (!tetheringHelperEnabled) {
            return TetheringHelperStatus.DISABLED
        }
        return when (signalSenderStatus) {
            SignalSenderStatus.ACTIVE -> TetheringHelperStatus.ACTIVE
            SignalSenderStatus.INACTIVE -> TetheringHelperStatus.INACTIVE
        }
    }

    /**
     * Starts the first time setup if necessary. First time setup is used to grant permissions
     * and to set the phone name that is being shown in macOS.
     *
     * @return true if first time setup is necessary, false otherwise
     */
    private fun maybeStartFirstTimeSetup(): Boolean {
        val firstTimeSetupFinished = sharedPreferences.getBoolean(SharedPreferencesKeys.firstTimeSetupFinished, false)
        if (firstTimeSetupFinished && Permissions.arePermissionsGranted(this)) {
            return false
        }

        startActivity(Intent(this, FirstTimeSetupActivity::class.java))
        finish()
        return true
    }
}