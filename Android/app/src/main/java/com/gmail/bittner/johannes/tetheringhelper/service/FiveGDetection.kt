package com.gmail.bittner.johannes.tetheringhelper.service

import android.os.Build
import android.telephony.TelephonyCallback
import android.telephony.TelephonyDisplayInfo
import android.telephony.TelephonyManager
import android.util.Log
import androidx.annotation.RequiresApi
import java.util.concurrent.Executors

private const val TAG = "FiveGDetection"

/**
 * This class provides `telephonyDisplayInfo`, which is used for 5G detection.
 * NSA (non-standalone) 5G networks are not detectable with dataNetworkType
 *
 * This class also exists to avoid `NoClassDefFoundError` exceptions for class TelephonyCallback,
 * which happen on older Android API levels when this class is referenced in SignalSender.
 *
 * @see https://developer.android.com/about/versions/11/features/5g#detection
 */
class FiveGDetection(
    private val telephonyManager: TelephonyManager
) {
    var telephonyDisplayInfo: TelephonyDisplayInfo? = null

    private var android12AndUpCallback: TelephonyCallback? = null
    @Suppress("DEPRECATION")
    private var android11Callback: android.telephony.PhoneStateListener? = null

    init {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            setupForAndroid12AndUp()
        } else if (Build.VERSION.SDK_INT == Build.VERSION_CODES.R) {
            setupForAndroid11()
        }
    }

    fun teardown() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            teardownForAndroid12AndUp()
        } else if (Build.VERSION.SDK_INT == Build.VERSION_CODES.R) {
            teardownForAndroid11()
        }
    }

    @RequiresApi(Build.VERSION_CODES.S)
    private fun setupForAndroid12AndUp() {
        android12AndUpCallback = object :
            TelephonyCallback(), TelephonyCallback.DisplayInfoListener {
            override fun onDisplayInfoChanged(telephonyDisplayInfo: TelephonyDisplayInfo) {
                Log.d(TAG, "Android 12 and up, display info changed: $telephonyDisplayInfo")
                this@FiveGDetection.telephonyDisplayInfo = telephonyDisplayInfo
            }
        }

        android12AndUpCallback?.let { callback ->
            telephonyManager.registerTelephonyCallback(
                Executors.newSingleThreadExecutor(),
                callback
            )
        }
    }

    @RequiresApi(Build.VERSION_CODES.S)
    private fun teardownForAndroid12AndUp() {
        android12AndUpCallback?.let { callback ->
            telephonyManager.unregisterTelephonyCallback(callback)
        }
    }

    @Suppress("DEPRECATION")
    @RequiresApi(Build.VERSION_CODES.R)
    private fun setupForAndroid11() {
        android11Callback = object : android.telephony.PhoneStateListener() {
            override fun onDisplayInfoChanged(telephonyDisplayInfo: TelephonyDisplayInfo) {
                try {
                    super.onDisplayInfoChanged(telephonyDisplayInfo)
                } catch (e: SecurityException) {
                    Log.e(
                        TAG,
                        "Required permissions missing. This should never happen, please report a bug."
                    )
                    throw e
                }
                Log.d(TAG, "Android 11, display info changed: $telephonyDisplayInfo")
                this@FiveGDetection.telephonyDisplayInfo = telephonyDisplayInfo
            }
        }
        telephonyManager.listen(
            android11Callback,
            android.telephony.PhoneStateListener.LISTEN_DISPLAY_INFO_CHANGED
        )
    }

    @Suppress("DEPRECATION")
    private fun teardownForAndroid11() {
        android11Callback?.let { callback ->
            telephonyManager.listen(
                callback,
                android.telephony.PhoneStateListener.LISTEN_NONE
            )
        }
    }
}
