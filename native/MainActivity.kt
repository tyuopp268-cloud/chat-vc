
package com.example.voice_changer

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "voice_changer/audio"
    private val microphoneRequestCode = 1001
    private var pendingStartResult: MethodChannel.Result? = null
    private var pendingEffects: Map<String, Any>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->

            when (call.method) {
                "startAudio" -> {
                    val effects = call.arguments as? Map<String, Any> ?: emptyMap()

                    if (ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.RECORD_AUDIO
                        ) != PackageManager.PERMISSION_GRANTED
                    ) {
                        pendingStartResult?.error(
                            "REQUEST_REPLACED",
                            "คำขอก่อนหน้าถูกแทนที่",
                            null
                        )
                        pendingStartResult = result
                        pendingEffects = effects

                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.RECORD_AUDIO),
                            microphoneRequestCode
                        )
                    } else {
                        startAudioService(effects, result)
                    }
                }

                "setEffects" -> {
                    val effects = call.arguments as? Map<String, Any> ?: emptyMap()
                    val intent = Intent(this, AudioService::class.java).apply {
                        action = AudioService.ACTION_SET_EFFECTS
                        putExtra("pitch", (effects["pitch"] as? Number)?.toFloat() ?: 1f)
                        putExtra("echo", (effects["echo"] as? Number)?.toFloat() ?: 0f)
                        putExtra("bass", (effects["bass"] as? Number)?.toFloat() ?: 0f)
                    }

                    try {
                        startService(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("EFFECTS_FAILED", e.message, null)
                    }
                }

                "stopAudio" -> {
                    stopService(Intent(this, AudioService::class.java))
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun startAudioService(
        effects: Map<String, Any>,
        result: MethodChannel.Result
    ) {
        val intent = Intent(this, AudioService::class.java).apply {
            action = AudioService.ACTION_START
            putExtra("pitch", (effects["pitch"] as? Number)?.toFloat() ?: 1f)
            putExtra("echo", (effects["echo"] as? Number)?.toFloat() ?: 0f)
            putExtra("bass", (effects["bass"] as? Number)?.toFloat() ?: 0f)
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                ContextCompat.startForegroundService(this, intent)
            } else {
                startService(intent)
            }
            result.success(true)
        } catch (e: Exception) {
            result.error("START_FAILED", e.message ?: "เริ่มระบบเสียงไม่สำเร็จ", null)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == microphoneRequestCode) {
            val result = pendingStartResult
            val effects = pendingEffects ?: emptyMap()

            pendingStartResult = null
            pendingEffects = null

            if (grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            ) {
                if (result != null) {
                    startAudioService(effects, result)
                }
            } else {
                result?.error(
                    "MICROPHONE_DENIED",
                    "กรุณาอนุญาตให้แอปใช้ไมโครโฟน",
                    null
                )
            }
        }
    }
}
