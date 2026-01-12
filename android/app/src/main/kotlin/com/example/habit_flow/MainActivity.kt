package com.example.habit_flow

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.habit.app/alarm"

    companion object {
        const val ALARM_CHANNEL_ID = "habit_flow_alarm_channel"
        const val REMINDER_CHANNEL_ID = "habit_flow_reminder_channel"
        const val ACTION_ALARM_TRIGGER = "com.example.habit_flow.ALARM_TRIGGER"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        window.addFlags(
            android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        createNotificationChannels()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleTask" -> {
                    val id = call.argument<Int>("id") ?: 0
                    val timeMs = call.argument<Long>("timeMs") ?: 0L
                    val title = call.argument<String>("title") ?: "Habit"
                    val body = call.argument<String>("body") ?: "Time for your habit"
                    val isAlarm = call.argument<Boolean>("isAlarm") ?: true
                    val audio = call.argument<Boolean>("audio") ?: true
                    val vibrate = call.argument<Boolean>("vibrate") ?: true
                    scheduleTask(id, timeMs, title, body, isAlarm, audio, vibrate)
                    result.success(true)
                }
                "cancelTask" -> {
                    val id = call.argument<Int>("id") ?: 0
                    cancelTask(id)
                    result.success(true)
                }
                "stopAlarm" -> {
                    stopAlarmService()
                    result.success(true)
                }
                "checkExactAlarmPermission" -> {
                    result.success(canScheduleExactAlarms())
                }
                "requestExactAlarmPermission" -> {
                    requestExactAlarmPermission()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)

            // 1. Alarm Channel (High Importance, Sound handled by MediaPlayer usually, but channel can have it too)
            // We set sound to null here because AlarmService plays it via MediaPlayer for looping.
            val alarmChannel = NotificationChannel(
                ALARM_CHANNEL_ID,
                "Alarms",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "High priority alarms"
                setSound(null, null) 
                enableVibration(false) // Handled manually
            }

            // 2. Reminder Channel (Default/High Importance, System Sound)
            val reminderChannel = NotificationChannel(
                REMINDER_CHANNEL_ID,
                "Reminders",
                NotificationManager.IMPORTANCE_DEFAULT // or HIGH if we want heads-up
            ).apply {
                description = "Gentle reminders"
                enableVibration(true)
            }

            notificationManager.createNotificationChannel(alarmChannel)
            notificationManager.createNotificationChannel(reminderChannel)
        }
    }

    private fun scheduleTask(id: Int, timeMs: Long, title: String, body: String, isAlarm: Boolean, audio: Boolean, vibrate: Boolean) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, AlarmReceiver::class.java).apply {
            action = ACTION_ALARM_TRIGGER
            putExtra("ALARM_ID", id)
            putExtra("ALARM_TITLE", title)
            putExtra("ALARM_BODY", body)
            putExtra("IS_ALARM", isAlarm)
            putExtra("ALARM_AUDIO", audio)
            putExtra("ALARM_VIBRATE", vibrate)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Use SetExactAndAllowWhileIdle for critical alarms.
        // For Reminders, we could use setExact, but to be safe and consistent we stick to one.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (alarmManager.canScheduleExactAlarms()) {
                val alarmClockInfo = AlarmManager.AlarmClockInfo(timeMs, pendingIntent)
                alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
                Log.d("MainActivity", "Scheduled Task via setAlarmClock ID: $id (Alarm: $isAlarm) at $timeMs")
            } else {
                Log.w("MainActivity", "Cannot schedule exact alarm - permission denied")
            }
        } else {
            val alarmClockInfo = AlarmManager.AlarmClockInfo(timeMs, pendingIntent)
            alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
            Log.d("MainActivity", "Scheduled Task via setAlarmClock ID: $id (Alarm: $isAlarm) at $timeMs")
        }
    }

    private fun cancelTask(id: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, AlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
        Log.d("MainActivity", "Canceled Task ID: $id")
    }

    private fun stopAlarmService() {
        val intent = Intent(this, AlarmService::class.java).apply {
            action = AlarmService.ACTION_STOP
        }
        startService(intent)
    }

    private fun canScheduleExactAlarms(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.canScheduleExactAlarms()
        } else {
            true
        }
    }

    private fun requestExactAlarmPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
            startActivity(intent)
        }
    }
}
