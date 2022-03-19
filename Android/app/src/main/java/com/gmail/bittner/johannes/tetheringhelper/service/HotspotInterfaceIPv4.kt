package com.gmail.bittner.johannes.tetheringhelper.service

import android.content.Context
import android.net.wifi.WifiManager
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import java.math.BigInteger
import java.net.InetAddress
import java.net.NetworkInterface
import java.net.UnknownHostException
import java.nio.ByteOrder

private const val TAG = "HotspotInterfaceIPv4"

/**
 * This class' responsibility is to find the IPv4 of the hotspot interface.
 * There is currently no API to do this, so we do it heuristically and assume that the IPv4
 * starts with "192", and it's the only interface except the regular WiFi interface that
 * starts with "192".
 */
class HotspotInterfaceIPv4(private val context: Context) {
    fun getHotspotIPv4Address(): String? {
        val ipv4Addresses = getNetworkInterfaceIPv4Addresses()
        val wifiIpAddress = getWifiIpAddress()

        Log.d(TAG, "IPv4 addresses:")
        for (ipv4 in ipv4Addresses) {
            Log.d(TAG, ipv4)
        }
        Log.d(TAG, "Wifi IPv4 address: $wifiIpAddress")

        val possibleHotspotAddresses = ipv4Addresses.filter {
            it != wifiIpAddress && it.startsWith("192")
        }

        Log.d(TAG, "Possible addresses: $possibleHotspotAddresses")
        if (possibleHotspotAddresses.count() == 1) {
            return possibleHotspotAddresses[0]
        }

        return null
    }

    private fun isIPv4(input: String): Boolean {
        return Regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$").matches(input)
    }

    private fun getNetworkInterfaceIPv4Addresses(): Array<String> {
        val networkInterfaces = NetworkInterface.getNetworkInterfaces() ?: run {
            Log.d(TAG, "No interfaces, INTERNET permission might be missing")
            return emptyArray()
        }

        var addresses = emptyArray<String>()
        for (networkInterface in networkInterfaces) {
            val inetAddresses = networkInterface.inetAddresses ?: continue
            for (inetAddress in inetAddresses) {
                val hostAddress = inetAddress.hostAddress ?: continue
                if (isIPv4(hostAddress)) {
                    addresses += hostAddress
                }
            }
        }
        return addresses
    }

    @Suppress("DEPRECATION")
    private fun getWifiIpAddress(): String? {
        val wifiManager = context.getSystemService(AppCompatActivity.WIFI_SERVICE) as WifiManager
        var ipAddress = wifiManager.connectionInfo.ipAddress

        if (ByteOrder.nativeOrder().equals(ByteOrder.LITTLE_ENDIAN)) {
            ipAddress = Integer.reverseBytes(ipAddress)
        }

        val inetAddress = try {
            InetAddress.getByAddress(BigInteger.valueOf(ipAddress.toLong()).toByteArray())
        } catch (ex: UnknownHostException) {
            null
        }
        return inetAddress?.hostAddress
    }
}
