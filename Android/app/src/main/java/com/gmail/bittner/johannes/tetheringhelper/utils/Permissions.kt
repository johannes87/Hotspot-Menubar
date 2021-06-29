package com.gmail.bittner.johannes.tetheringhelper.utils

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat

class Permissions {
    companion object {
        val requiredRuntimePermissions = arrayOf(Manifest.permission.READ_PHONE_STATE)

        fun allPermissionsGranted(context: Context): Boolean {
            return requiredRuntimePermissions.all { permission ->
                val permissionCheckResult = ContextCompat.checkSelfPermission(context, permission)
                permissionCheckResult == PackageManager.PERMISSION_GRANTED
            }
        }
    }
}