package com.example.frontend

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.telephony.SmsManager
import android.os.Build

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.stepzero.sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sendSMS") {
                val phone = call.argument<String>("phone")
                val msg = call.argument<String>("msg")
                if (phone != null && msg != null) {
                    try {
                        val smsManager: SmsManager;
                        if (Build.VERSION.SDK_INT >= 31) {
                            smsManager = this.getSystemService(SmsManager::class.java)!!;
                        } else {
                            smsManager = SmsManager.getDefault();
                        }
                        smsManager.sendTextMessage(phone, null, msg, null, null)
                        result.success("SMS Sent")
                    } catch (e: Exception) {
                        result.error("ERR", e.message, null)
                    }
                } else {
                    result.error("INVALID_ARGS", "Phone and msg required", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
