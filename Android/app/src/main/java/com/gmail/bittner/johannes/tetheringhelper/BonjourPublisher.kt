package com.gmail.bittner.johannes.tetheringhelper

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo

/**
 * This class publishes the TetheringHelper Bonjour service to the local network.
 */
class BonjourPublisher (val serviceName: String, val port: Int, val context: Context) {
    private val serviceType = "_tetheringhelper._tcp"
    private var registeredServiceName: String? = null
    private var nsdManager: NsdManager? = null

    private val registrationListener = object : NsdManager.RegistrationListener {
        override fun onServiceRegistered(NsdServiceInfo: NsdServiceInfo) {
            // Save the service name. Android may have changed it in order to
            // resolve a conflict, so update the name you initially requested
            // with the name Android actually used.
            registeredServiceName = NsdServiceInfo.serviceName
        }

        override fun onRegistrationFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
            // TODO: Registration failed! Put debugging code here to determine why.
        }

        override fun onServiceUnregistered(arg0: NsdServiceInfo) {
            // TODO: Service has been unregistered. This only happens when you call
            // NsdManager.unregisterService() and pass in this listener.
        }

        override fun onUnregistrationFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
            // TODO: Unregistration failed. Put debugging code here to determine why.
        }
    }


    fun publish() {
        val serviceInfo = NsdServiceInfo().apply {
            // The name is subject to change based on conflicts
            // with other services advertised on the same network.
            serviceName = this@BonjourPublisher.serviceName
            serviceType = this@BonjourPublisher.serviceType
            setPort(this@BonjourPublisher.port)
        }


        nsdManager = (context.getSystemService(Context.NSD_SERVICE) as NsdManager).apply {
            registerService(serviceInfo, NsdManager.PROTOCOL_DNS_SD, this@BonjourPublisher.registrationListener)
        }
    }
}