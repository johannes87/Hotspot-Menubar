package com.gmail.bittner.johannes.tetheringhelper.ui

import android.Manifest
import android.content.DialogInterface
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Log
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.databinding.DataBindingUtil
import androidx.preference.PreferenceManager
import com.gmail.bittner.johannes.tetheringhelper.R
import com.gmail.bittner.johannes.tetheringhelper.SharedPreferencesKeys
import com.gmail.bittner.johannes.tetheringhelper.databinding.ActivityFirstTimeSetupBinding

class FirstTimeSetupActivity : AppCompatActivity() {
    private lateinit var binding: ActivityFirstTimeSetupBinding
    private lateinit var requestPermissionsLauncher: ActivityResultLauncher<Array<String>>
    private lateinit var sharedPreferences: SharedPreferences
    private val requiredRuntimePermissions = arrayOf(Manifest.permission.READ_PHONE_STATE)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = DataBindingUtil.setContentView(this, R.layout.activity_first_time_setup)
        sharedPreferences = PreferenceManager.getDefaultSharedPreferences(this)

        requestPermissionsLauncher = registerForActivityResult(
            ActivityResultContracts.RequestMultiplePermissions()
        ) { result ->
            binding.permissionsGranted = result.entries.all { it.value == true }
        }

        binding.permissionsGranted = requiredRuntimePermissions.all { permission ->
            val permissionCheckResult = ContextCompat.checkSelfPermission(this, permission)
            permissionCheckResult == PackageManager.PERMISSION_GRANTED
        }

        binding.editTextPhoneName.setText(android.os.Build.MODEL)
        binding.buttonRequestPermissions.setOnClickListener { requestRuntimePermissions() }
        binding.buttonWhyPermissions.setOnClickListener { showWhyPermissions() }
        binding.buttonContinue.setOnClickListener { finishFirstTimeSetup() }
    }

    private fun showWhyPermissions() {
        val builder = AlertDialog.Builder(this)
        builder.apply {
            setTitle(R.string.first_time_setup_why_dialog_title)
            setMessage(R.string.first_time_setup_why_dialog_message)
            setPositiveButton(R.string.first_time_setup_why_dialog_positive_button_text) { _,_ -> }
        }

        builder.create().show()
    }

    private fun requestRuntimePermissions() {
        requestPermissionsLauncher.launch(requiredRuntimePermissions)
    }

    private fun finishFirstTimeSetup() {
        sharedPreferences.edit().apply {
            putString(SharedPreferencesKeys.phoneName, binding.editTextPhoneName.text.toString())
            putBoolean(SharedPreferencesKeys.firstTimeSetupFinished, true)
            apply()
        }

        startActivity(Intent(this, MainActivity::class.java))
        finish()
    }
}