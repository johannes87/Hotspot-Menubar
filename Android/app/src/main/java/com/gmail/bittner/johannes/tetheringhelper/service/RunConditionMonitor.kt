package com.gmail.bittner.johannes.tetheringhelper.service

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleObserver
import androidx.lifecycle.OnLifecycleEvent
import androidx.preference.PreferenceManager
import com.gmail.bittner.johannes.tetheringhelper.utils.SharedPreferencesKeys

private const val TAG = "RunConditionMonitor"

/**
 * RunConditionManager's job is to decide if SignalSenderService needs to be started or stopped,
 * and start/stop the service if the user toggles the "tetheringHelperEnabled" preference
 */
class RunConditionMonitor(
    private val context: Context
    ): LifecycleObserver  {
    private val sharedPreferences = PreferenceManager.getDefaultSharedPreferences(context)
    private val tetheringHelperEnabled: Boolean
        get() = sharedPreferences.getBoolean(SharedPreferencesKeys.tetheringHelperEnabled, false)
    private val sharedPreferenceChangeListener =
        SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
            if (key == SharedPreferencesKeys.tetheringHelperEnabled) {
                Log.d(TAG, "'$key' preference changed")
                manageRunConditions()
            }
        }

    @OnLifecycleEvent(Lifecycle.Event.ON_RESUME)
    private fun onResume() {
        sharedPreferences.registerOnSharedPreferenceChangeListener(sharedPreferenceChangeListener)
        manageRunConditions()
    }

    @OnLifecycleEvent(Lifecycle.Event.ON_PAUSE)
    private fun onPause() {
        sharedPreferences.unregisterOnSharedPreferenceChangeListener(sharedPreferenceChangeListener)
    }

    private fun manageRunConditions() {
        val signalSenderServiceIntent = Intent(context, SignalSenderService::class.java)

        if (tetheringHelperEnabled) {
            Log.d(TAG, "Starting service because TetheringHelper is enabled")
            context.startForegroundService(signalSenderServiceIntent)
        } else {
            Log.d(TAG, "Stopping service because TetheringHelper is disabled")
            context.stopService(signalSenderServiceIntent)
        }
    }
}