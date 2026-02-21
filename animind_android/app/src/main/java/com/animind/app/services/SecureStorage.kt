package com.animind.app.services

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

object SecureStorage {
    private const val PREF_NAME = "animind_secure_prefs"
    private const val KEY_API = "gemini_api_key"

    private fun getPrefs(context: Context): SharedPreferences {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()

        return EncryptedSharedPreferences.create(
            context,
            PREF_NAME,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
        )
    }

    fun saveApiKey(context: Context, key: String) {
        getPrefs(context).edit().putString(KEY_API, key).apply()
    }

    fun loadApiKey(context: Context): String {
        return getPrefs(context).getString(KEY_API, "") ?: ""
    }

    fun clearApiKey(context: Context) {
        getPrefs(context).edit().remove(KEY_API).apply()
    }
}
