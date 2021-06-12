package com.gmail.bittner.johannes.tetheringhelper.ui

import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import androidx.databinding.DataBindingUtil
import androidx.preference.PreferenceManager
import com.gmail.bittner.johannes.tetheringhelper.R
import com.gmail.bittner.johannes.tetheringhelper.SharedPreferencesKeys
import com.gmail.bittner.johannes.tetheringhelper.SignalSender
import com.gmail.bittner.johannes.tetheringhelper.databinding.ActivityMainBinding

// TODO: make it possible to connect to service when phone is in standby mode
// TODO: stop broadcasting service when app is swiped-away in android task manager (or disabled, or not in hotspot mode, etc)

class MainActivity : AppCompatActivity() {
    private lateinit var signalSender: SignalSender
    private lateinit var binding: ActivityMainBinding
    private lateinit var sharedPreferences: SharedPreferences

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = DataBindingUtil.setContentView(this, R.layout.activity_main)
        sharedPreferences = PreferenceManager.getDefaultSharedPreferences(this)

        if (maybeStartFirstTimeSetup()) {
            return
        }

        signalSender = SignalSender(
            phoneName = sharedPreferences.getString(SharedPreferencesKeys.phoneName, "")!!,
            context = this
        )
        signalSender.start()

        binding.networkPortTextView.text = signalSender.listenPort.toString()
    }

    /**
     * Starts the first time setup if necessary
     *
     * @return true if first time setup is necessary, false otherwise
     */
    private fun maybeStartFirstTimeSetup(): Boolean {
        val firstTimeSetupFinished = sharedPreferences.getBoolean(SharedPreferencesKeys.firstTimeSetupFinished, false)
        if (firstTimeSetupFinished) {
            return false
        }

        startActivity(Intent(this, FirstTimeSetupActivity::class.java))
        finish();
        return true;
    }
}