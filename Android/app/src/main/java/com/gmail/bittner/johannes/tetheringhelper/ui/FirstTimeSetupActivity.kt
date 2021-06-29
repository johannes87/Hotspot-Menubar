package com.gmail.bittner.johannes.tetheringhelper.ui

import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.databinding.DataBindingUtil
import androidx.preference.PreferenceManager
import com.gmail.bittner.johannes.tetheringhelper.R
import com.gmail.bittner.johannes.tetheringhelper.SharedPreferencesKeys
import com.gmail.bittner.johannes.tetheringhelper.databinding.ActivityFirstTimeSetupBinding
import com.gmail.bittner.johannes.tetheringhelper.utils.Permissions

class FirstTimeSetupActivity : AppCompatActivity() {
    private lateinit var binding: ActivityFirstTimeSetupBinding
    private lateinit var requestPermissionsLauncher: ActivityResultLauncher<Array<String>>
    private lateinit var sharedPreferences: SharedPreferences

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = DataBindingUtil.setContentView(this, R.layout.activity_first_time_setup)
        sharedPreferences = PreferenceManager.getDefaultSharedPreferences(this)

        requestPermissionsLauncher = registerForActivityResult(
            ActivityResultContracts.RequestMultiplePermissions()
        ) { result ->
            binding.permissionsGranted = result.entries.all { it.value == true }
        }

        binding.permissionsGranted = Permissions.allPermissionsGranted(this)

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
        requestPermissionsLauncher.launch(Permissions.requiredRuntimePermissions)
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