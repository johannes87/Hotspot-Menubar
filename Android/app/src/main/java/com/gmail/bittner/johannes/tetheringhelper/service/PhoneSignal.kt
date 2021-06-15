package com.gmail.bittner.johannes.tetheringhelper.service

import android.telephony.TelephonyManager
import android.util.Log

enum class SignalQuality(val quality: Int) {
    NO_SIGNAL(0),
    ONE_BAR(1),
    TWO_BARS(2),
    THREE_BARS(3),
    FOUR_BARS(4);

    companion object {
        private val mapping = values().associateBy(SignalQuality::quality)
        fun fromQuality(quality: Int): SignalQuality = mapping[quality]!!
    }
}

enum class SignalType(val type: String) {
    NO_SIGNAL(""),
    TWO_G("2G"),
    EDGE("E"),
    THREE_G("3G"),
    HSDPA("H"),
    LTE("LTE"),
    FIVE_G("5G");

    companion object {
        fun fromDataNetworkType(dataNetworkType: Int): SignalType {
            // TODO: support 5G
            return when (dataNetworkType) {
                TelephonyManager.NETWORK_TYPE_GPRS -> TWO_G
                TelephonyManager.NETWORK_TYPE_EDGE -> EDGE
                TelephonyManager.NETWORK_TYPE_CDMA -> TWO_G
                TelephonyManager.NETWORK_TYPE_1xRTT -> TWO_G
                TelephonyManager.NETWORK_TYPE_IDEN -> TWO_G
                TelephonyManager.NETWORK_TYPE_UMTS -> THREE_G
                TelephonyManager.NETWORK_TYPE_EVDO_0 -> THREE_G
                TelephonyManager.NETWORK_TYPE_EVDO_A -> THREE_G
                TelephonyManager.NETWORK_TYPE_HSDPA -> HSDPA
                TelephonyManager.NETWORK_TYPE_HSUPA -> HSDPA
                TelephonyManager.NETWORK_TYPE_HSPA -> HSDPA
                TelephonyManager.NETWORK_TYPE_EVDO_B -> HSDPA
                TelephonyManager.NETWORK_TYPE_EHRPD -> HSDPA
                TelephonyManager.NETWORK_TYPE_HSPAP -> HSDPA
                TelephonyManager.NETWORK_TYPE_LTE -> LTE
                else -> NO_SIGNAL
            }
        }
    }
}

class PhoneSignal(val quality: SignalQuality, val type: SignalType) {
    companion object {
        private const val TAG = "PhoneSignal"

        fun getSignal(telephonyManager: TelephonyManager): PhoneSignal {
            val quality = SignalQuality.fromQuality(telephonyManager.signalStrength!!.level)
            var type: SignalType? = null

            try {
                type = SignalType.fromDataNetworkType(telephonyManager.dataNetworkType)
            } catch (e: SecurityException) {
                Log.e(TAG, "Required permissions missing. This should never happen, please report a bug.")
            }

            return PhoneSignal(quality, type!!)
        }
    }

    fun toJSON(): String {
        return "{\"quality\":${quality.quality},\"type\":\"${type.type}\"}"
    }
}