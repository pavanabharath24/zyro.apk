package com.example.habit_flow

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import androidx.core.app.NotificationCompat

class AlarmService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null
    
    companion object {
        const val CHANNEL_ID = "habit_flow_alarm_channel"
        const val CHANNEL_NAME = "Habit Alarms"
        const val ACTION_STOP = "STOP_ALARM"
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
    }

    private val activeAlarmTitles = mutableListOf<String>()

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopRingtone()
            stopVibration()
            activeAlarmTitles.clear()
            stopForeground(true)
            stopSelf()
            return START_NOT_STICKY
        }

        val title = intent?.getStringExtra("ALARM_TITLE") ?: "Habit Reminder"
        val audio = intent?.getBooleanExtra("ALARM_AUDIO", true) ?: true
        val vibrate = intent?.getBooleanExtra("ALARM_VIBRATE", true) ?: true
        
        // val body = intent?.getStringExtra("ALARM_BODY") ?: "Time for your habit!" 
        // We will focus on merging Titles for the main display.

        if (!activeAlarmTitles.contains(title)) {
            activeAlarmTitles.add(title)
        }
        
        val combinedTitle = activeAlarmTitles.joinToString(", ")
        val combinedBody = "Time for: $combinedTitle"

        // 1. Acquire WakeLock
        acquireWakeLock()
        
        // 2. Start Foreground with Full Screen Intent
        val notification = buildNotification("Habit Alarms", combinedBody)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            startForeground(1001, notification, android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(1001, notification)
        }
        
        // 3. Play Ringtone & Vibrate (Ensure it's playing)
        // Only if audio is enabled
        if (audio) {
             if (mediaPlayer == null || !mediaPlayer!!.isPlaying) {
                 playRingtone()
             }
        }
        
        // Only if vibration is enabled
        if (vibrate) {
             startVibration()
        }
        
        // 4. Notify Flutter UI via Broadcast (optional, or rely on onNewIntent)
        // We rely on the Notification's FullScreenIntent triggering MainActivity.onNewIntent
        
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        stopRingtone()
        stopVibration()
        releaseWakeLock()
        Log.d("AlarmService", "Service Destroyed")
    }

    private fun acquireWakeLock() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
            "HabitFlow:NativeAlarmService"
        )
        wakeLock?.acquire(10 * 60 * 1000L /*10 minutes*/)
    }

    private fun releaseWakeLock() {
        if (wakeLock?.isHeld == true) {
            wakeLock?.release()
        }
    }

    private fun playRingtone() {
        try {
            var alarmUri: Uri? = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            if (alarmUri == null) {
                alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            }
            
            mediaPlayer = MediaPlayer().apply {
                setDataSource(applicationContext, alarmUri!!)
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                isLooping = true
                prepare()
                start()
            }
        } catch (e: Exception) {
            Log.e("AlarmService", "Error playing ringtone", e)
        }
    }

    private fun stopRingtone() {
        try {
            mediaPlayer?.stop()
            mediaPlayer?.release()
            mediaPlayer = null
        } catch (e: Exception) {
            Log.e("AlarmService", "Error stopping ringtone", e)
        }
    }

    private fun startVibration() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator?.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 1000, 1000), 0))
        } else {
            vibrator?.vibrate(longArrayOf(0, 1000, 1000), 0)
        }
    }

    private fun stopVibration() {
        vibrator?.cancel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Full screen alarm notifications"
                setSound(null, null) // Sound is handled by MediaPlayer
                enableVibration(false) // Vibration handled manually
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(title: String, body: String): Notification {
        // Stop Action Intent
        val stopIntent = Intent(this, AlarmService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Full Screen Intent (Activity to launch)
        val fullScreenIntent = Intent(this, MainActivity::class.java).apply {
             flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
             // We can pass data to open a specific screen in Flutter
             putExtra("route", "/alarm-ring")
             putExtra("title", title)
             putExtra("body", body)
        }
        val fullScreenPendingIntent = PendingIntent.getActivity(
            this, 0, fullScreenIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher) // Ensure this resource exists
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .addAction(R.drawable.launch_background, "STOP", stopPendingIntent) // Using standard icon as placeholder if needed, or simple text action
            .setOngoing(true) 
            .setAutoCancel(false)
            .build()
    }
}
