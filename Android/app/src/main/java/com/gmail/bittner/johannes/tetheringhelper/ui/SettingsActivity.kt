package com.gmail.bittner.johannes.tetheringhelper.ui

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.preference.Preference
import androidx.preference.PreferenceFragmentCompat
import androidx.preference.SwitchPreferenceCompat
import com.gmail.bittner.johannes.tetheringhelper.R
import com.gmail.bittner.johannes.tetheringhelper.SharedPreferencesKeys

class SettingsActivity : AppCompatActivity() {
    companion object {
        class SettingsFragment : PreferenceFragmentCompat() {
            override fun onCreatePreferences(savedInstanceState: Bundle?, rootKey: String?) {
                val context = preferenceManager.context
                val screen = preferenceManager.createPreferenceScreen(context)

                val tetheringHelperEnabledPreference = SwitchPreferenceCompat(context)
                tetheringHelperEnabledPreference.key = SharedPreferencesKeys.tetheringHelperEnabled
                tetheringHelperEnabledPreference.title = getString(R.string.preference_tetheringhelper_enabled_title)
                tetheringHelperEnabledPreference.summaryProvider = Preference.SummaryProvider<SwitchPreferenceCompat> { preference ->
                    if (preference.isChecked) {
                        getString(R.string.preference_tetheringhelper_enabled_true_summary)
                    } else {
                        getString(R.string.preference_tetheringhelper_enabled_false_summary)
                    }
                }

                screen.addPreference(tetheringHelperEnabledPreference)
                preferenceScreen = screen
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContentView(R.layout.activity_settings)

        supportFragmentManager
            .beginTransaction()
            .replace(R.id.settings_container, SettingsFragment())
            .commit()
    }
}