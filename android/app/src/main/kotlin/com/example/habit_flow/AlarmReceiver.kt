package com.example.habit_flow

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import androidx.core.app.NotificationCompat

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.d("AlarmReceiver", "Received intent: ${intent.action}")

        if (intent.action != MainActivity.ACTION_ALARM_TRIGGER) {
            Log.d("AlarmReceiver", "Ignoring unknown intent action: ${intent.action}")
            // Eventually handle BOOT_COMPLETED here to reschedule alarms if needed
            return
        }

        val id = intent.getIntExtra("ALARM_ID", 0)
        val title = intent.getStringExtra("ALARM_TITLE") ?: "Habit Reminder"
        val body = intent.getStringExtra("ALARM_BODY") ?: "Time for your habit"
        val isAlarm = intent.getBooleanExtra("IS_ALARM", true)
        val audio = intent.getBooleanExtra("ALARM_AUDIO", true)
        val vibrate = intent.getBooleanExtra("ALARM_VIBRATE", true)

        Log.d("AlarmReceiver", "Received id=$id, isAlarm=$isAlarm, audio=$audio, vibrate=$vibrate")

        if (isAlarm) {
            // HIGH PRIORITY: Start Foreground Service
            val serviceIntent = Intent(context, AlarmService::class.java).apply {
                putExtra("ALARM_ID", id)
                putExtra("ALARM_TITLE", title)
                putExtra("ALARM_BODY", body)
                putExtra("ALARM_AUDIO", audio)
                putExtra("ALARM_VIBRATE", vibrate)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } else {
            // LOW PRIORITY: Notification + Single Vibrate
            triggerReminder(context, id, title, body)
        }
    }

    private fun triggerReminder(context: Context, id: Int, title: String, body: String) {
        val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        
        // 1. Single Vibration Pulse
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createOneShot(500, VibrationEffect.DEFAULT_AMPLITUDE))
        } else {
            vibrator.vibrate(500)
        }

        // 2. Standard Notification
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // Intent to open app when tapped
        val openAppIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = android.app.PendingIntent.getActivity(
            context, 
            id, 
            openAppIntent, 
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, MainActivity.REMINDER_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(id, notification)
    }
}
