package com.newsly.haber

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.newsly.haber/notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Uygulama başladığında varsayılan kanalı oluştur
        createDefaultNotificationChannel()
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "createNotificationChannel") {
                val id = call.argument<String>("id") ?: "high_importance_channel"
                val name = call.argument<String>("name") ?: "Haber Bildirimleri"
                val description = call.argument<String>("description") ?: "Önemli haber bildirimleri"
                val importance = call.argument<Int>("importance") ?: NotificationManager.IMPORTANCE_HIGH
                
                createNotificationChannel(id, name, description, importance)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }
    
    private fun createDefaultNotificationChannel() {
        createNotificationChannel(
            "high_importance_channel",
            "Haber Bildirimleri",
            "Önemli haber bildirimleri",
            NotificationManager.IMPORTANCE_HIGH
        )
    }
    
    private fun createNotificationChannel(id: String, name: String, description: String, importance: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(id, name, importance).apply {
                this.description = description
                enableLights(true)
                enableVibration(true)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
