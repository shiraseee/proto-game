package com.animind.app

import android.app.Application
import com.animind.app.services.DatabaseService

class AniMindApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        DatabaseService.initialize(this)
    }
}
