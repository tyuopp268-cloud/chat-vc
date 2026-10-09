
package com.example.voice_changer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import android.os.IBinder
import android.os.Process
import kotlin.math.max
import kotlin.math.min

class AudioService : Service() {

    companion object {
        const val ACTION_START = "com.example.voice_changer.START"
        const val ACTION_SET_EFFECTS = "com.example.voice_changer.SET_EFFECTS"
        private const val CHANNEL_ID = "voice_lab_audio"
        private const val NOTIFICATION_ID = 1001
    }

    @Volatile private var running = false
    @Volatile private var pitch = 1f
    @Volatile private var echo = 0f
    @Volatile private var bass = 0f

    private var recorder: AudioRecord? = null
    private var audioThread: Thread? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_SET_EFFECTS -> {
                pitch = intent.getFloatExtra("pitch", 1f).coerceIn(0.7f, 1.5f)
                echo = intent.getFloatExtra("echo", 0f).coerceIn(0f, 1f)
                bass = intent.getFloatExtra("bass", 0f).coerceIn(0f, 1f)
            }

            ACTION_START -> {
                pitch = intent.getFloatExtra("pitch", 1f).coerceIn(0.7f, 1.5f)
                echo = intent.getFloatExtra("echo", 0f).coerceIn(0f, 1f)
                bass = intent.getFloatExtra("bass", 0f).coerceIn(0f, 1f)

                if (!running) {
                    createNotificationChannel()
                    val notification = buildNotification()

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        startForeground(
                            NOTIFICATION_ID,
                            notification,
                            ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
                        )
                    } else {
                        startForeground(NOTIFICATION_ID, notification)
                    }

                    startRecording()
                }
            }
        }

        return START_NOT_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Voice Lab Audio",
                NotificationManager.IMPORTANCE_LOW
            )
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setContentTitle("Voice Lab")
            .setContentText("กำลังทำงานกับไมโครโฟน")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setOngoing(true)
            .build()
    }

    private fun startRecording() {
        val sampleRate = 16000
        val channelConfig = AudioFormat.CHANNEL_IN_MONO
        val encoding = AudioFormat.ENCODING_PCM_16BIT
        val minBuffer = AudioRecord.getMinBufferSize(
            sampleRate,
            channelConfig,
            encoding
        )

        if (minBuffer <= 0) {
            stopSelf()
            return
        }

        val bufferSize = max(minBuffer, 4096)

        try {
            val audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                sampleRate,
                channelConfig,
                encoding,
                bufferSize
            )

            if (audioRecord.state != AudioRecord.STATE_INITIALIZED) {
                audioRecord.release()
                stopSelf()
                return
            }

            recorder = audioRecord
            running = true
            audioRecord.startRecording()

            audioThread = Thread {
                Process.setThreadPriority(Process.THREAD_PRIORITY_AUDIO)
                val input = ShortArray(bufferSize / 2)

                var previousInput = 0f
                var lowFrequency = 0f

                while (running && !Thread.currentThread().isInterrupted) {
                    val count = try {
                        audioRecord.read(input, 0, input.size)
                    } catch (_: Exception) {
                        break
                    }

                    if (count <= 0) continue

                    for (i in 0 until count) {
                        val sample = input[i].toFloat()

                        lowFrequency += 0.08f * (sample - lowFrequency)
                        val highFrequency = sample - lowFrequency

                        val bassAdjusted = sample + lowFrequency * bass * 1.5f
                        val echoAdjusted = bassAdjusted + previousInput * echo * 0.35f

                        val output = (echoAdjusted + highFrequency * 0.02f)
                            .coerceIn(Short.MIN_VALUE.toFloat(), Short.MAX_VALUE.toFloat())

                        input[i] = output.toInt().toShort()
                        previousInput = sample
                    }

                    // ตัวอย่างนี้รับเสียงและประมวลผลในหน่วยความจำ
                    // ยังไม่ได้ส่งเสียงออกลำโพงหรือส่งเข้าแอปอื่น
                }
            }.also { it.start() }

        } catch (_: SecurityException) {
            running = false
            stopSelf()
        } catch (_: Exception) {
            running = false
            stopSelf()
        }
    }

    override fun onDestroy() {
        running = false

        try {
            audioThread?.interrupt()
            audioThread?.join(300)
        } catch (_: InterruptedException) {
            Thread.currentThread().interrupt()
        }

        audioThread = null

        try {
            recorder?.stop()
        } catch (_: Exception) {
        }

        recorder?.release()
        recorder = null

        super.onDestroy()
    }
}
