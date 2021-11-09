package com.gmail.bittner.johannes.tetheringhelper.ui

import android.content.ComponentName
import android.content.Intent
import android.content.ServiceConnection
import android.content.SharedPreferences
import android.os.Bundle
import android.os.IBinder
import android.util.Log
import android.view.View
import androidx.appcompat.app.AppCompatActivity
import androidx.databinding.DataBindingUtil
import androidx.preference.PreferenceManager
import com.gmail.bittner.johannes.tetheringhelper.R
import com.gmail.bittner.johannes.tetheringhelper.databinding.ActivityMainBinding
import com.gmail.bittner.johannes.tetheringhelper.service.RunConditionMonitor
import com.gmail.bittner.johannes.tetheringhelper.service.SignalSenderService
import com.gmail.bittner.johannes.tetheringhelper.service.SignalSenderServiceBinder
import com.gmail.bittner.johannes.tetheringhelper.service.SignalSenderStatus
import com.gmail.bittner.johannes.tetheringhelper.utils.Permissions
import com.gmail.bittner.johannes.tetheringhelper.utils.SharedPreferencesKeys
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

private const val TAG = "MainActivity"

class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding
    private lateinit var sharedPreferences: SharedPreferences
    private lateinit var runConditionMonitor: RunConditionMonitor

    private var signalSenderService: SignalSenderService? = null
    private var signalSenderStatus: SignalSenderStatus = SignalSenderStatus.INACTIVE

    private val tetheringHelperEnabled: Boolean
        get() = sharedPreferences.getBoolean(
            SharedPreferencesKeys.tetheringHelperEnabled,
            false
        )
    private val coroutineScope = CoroutineScope(Dispatchers.Main)

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            Log.d(TAG, "Service connected")
            signalSenderService = (service as? SignalSenderServiceBinder)?.service
            this@MainActivity.onServiceConnected()
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            Log.d(TAG, "Service disconnected")
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

        updateUI()

        binding.switchEnableService.setOnCheckedChangeListener { _, isChecked ->
            coroutineScope.launch {
                // hack: leave a bit time before service starting/stopping happens, to avoid
                // jumpy switch animation because starting/stopping happens in main thread
                delay(300)

                sharedPreferences.edit().apply {
                    putBoolean(SharedPreferencesKeys.tetheringHelperEnabled, isChecked)
                    apply()
                }

                if (isChecked) {
                    // service is destroyed when switch gets unchecked, so the connection is lost.
                    // we need to reconnect when switch gets checked.
                    connectToService()
                } else {
                    updateUI()
                }
            }
        }

        binding.buttonHowToConnectLink.setOnClickListener {
            startActivity(Intent(this, HowToConnectActivity::class.java))
        }
    }

    override fun onResume() {
        Log.d(TAG, "onResume")
        super.onResume()

        if (tetheringHelperEnabled && signalSenderService == null) {
            connectToService()
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

    private fun updateUI() {
        if (tetheringHelperEnabled) {
            binding.switchEnableService.isChecked = true
            binding.imageViewWifiSymbol.visibility = View.VISIBLE
            binding.buttonHowToConnectLink.visibility = View.VISIBLE
            binding.textViewServiceStatus.visibility = View.VISIBLE

            if (signalSenderStatus == SignalSenderStatus.ACTIVE) {
                binding.textViewServiceStatus.text =
                    getString(R.string.main_activity_service_status_hotspot_on)
            } else {
                binding.textViewServiceStatus.text =
                    getString(R.string.main_activity_service_status_hotspot_off)
            }
        } else {
            binding.switchEnableService.isChecked = false
            binding.imageViewWifiSymbol.visibility = View.INVISIBLE
            binding.buttonHowToConnectLink.visibility = View.INVISIBLE
            binding.textViewServiceStatus.visibility = View.INVISIBLE
        }
    }

    private fun connectToService() {
        Intent(this, SignalSenderService::class.java).also { intent ->
            bindService(intent, serviceConnection, 0)
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
            this.signalSenderStatus = status
            updateUI()
        }

        signalSenderService?.let { service ->
            this.signalSenderStatus = service.signalSenderStatus
        }

        updateUI()
    }

    /**
     * Starts the first time setup if necessary. First time setup is used to grant permissions
     * and to set the phone name that is being shown in macOS.
     *
     * @return true if first time setup is necessary, false otherwise
     */
    private fun maybeStartFirstTimeSetup(): Boolean {
        val firstTimeSetupFinished = sharedPreferences.getBoolean(
            SharedPreferencesKeys.firstTimeSetupFinished,
            false
        )
        if (firstTimeSetupFinished && Permissions.allPermissionsGranted(this)) {
            return false
        }

        startActivity(Intent(this, FirstTimeSetupActivity::class.java))
        finish()
        return true
    }
}
