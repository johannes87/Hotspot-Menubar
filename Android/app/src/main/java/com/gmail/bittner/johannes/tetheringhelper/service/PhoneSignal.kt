package com.gmail.bittner.johannes.tetheringhelper.service

import android.os.Build
import android.telephony.TelephonyDisplayInfo
import android.telephony.TelephonyManager
import android.util.Log

private const val TAG = "PhoneSignal"

enum class SignalQuality(val quality: Int) {
    // Suppress "unused" warnings because all these classes are used via "fromQuality"
    @Suppress("unused")
    NO_SIGNAL(0),
    @Suppress("unused")
    ONE_BAR(1),
    @Suppress("unused")
    TWO_BARS(2),
    @Suppress("unused")
    THREE_BARS(3),
    @Suppress("unused")
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
    FIVE_G("5G"),
    FIVE_G_PLUS("5G+");

    companion object {
        fun fromAndroidData(
            dataNetworkType: Int,
            telephonyDisplayInfo: TelephonyDisplayInfo?
        ): SignalType {
            // lots of edge cases; dataNetworkType alone is not sufficient to determine 5G
            // see the following links:
            // https://source.android.com/devices/tech/connect/acts-5g-testing
            // https://developer.android.com/reference/android/telephony/TelephonyDisplayInfo#OVERRIDE_NETWORK_TYPE_NR_ADVANCED
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R &&
                telephonyDisplayInfo != null
            ) {
                if (dataNetworkType == TelephonyManager.NETWORK_TYPE_LTE &&
                    telephonyDisplayInfo.overrideNetworkType == TelephonyDisplayInfo.OVERRIDE_NETWORK_TYPE_NR_NSA
                ) {
                    return FIVE_G
                }

                // Android 11 is still used and MMWAVE value might be returned
                @Suppress("DEPRECATION")
                if (Build.VERSION.SDK_INT == Build.VERSION_CODES.R &&
                    telephonyDisplayInfo.overrideNetworkType == TelephonyDisplayInfo.OVERRIDE_NETWORK_TYPE_NR_NSA_MMWAVE
                ) {
                    return FIVE_G_PLUS
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                    telephonyDisplayInfo.overrideNetworkType == TelephonyDisplayInfo.OVERRIDE_NETWORK_TYPE_NR_ADVANCED
                ) {
                    return FIVE_G_PLUS
                }
            }

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
                TelephonyManager.NETWORK_TYPE_NR -> FIVE_G
                else -> NO_SIGNAL
            }
        }
    }
}

class PhoneSignal(val quality: SignalQuality, val type: SignalType) {
    companion object {
        fun getSignal(
            telephonyManager: TelephonyManager,
            telephonyDisplayInfo: TelephonyDisplayInfo?
        ): PhoneSignal {
            val dataNetworkType: Int
            try {
                dataNetworkType = telephonyManager.dataNetworkType
            } catch (e: SecurityException) {
                Log.e(
                    TAG,
                    "Required permissions missing. This should never happen, please report a bug."
                )
                throw e
            }

            val quality = SignalQuality.fromQuality(telephonyManager.signalStrength!!.level)
            val type = SignalType.fromAndroidData(dataNetworkType, telephonyDisplayInfo)
            return PhoneSignal(quality, type)
        }
    }

    fun toJSON(): String {
        return "{\"quality\":${quality.quality},\"type\":\"${type.type}\"}"
    }
}
