package com.example.frontend

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import android.os.Build
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat

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
                        var targetSubId = -1

                        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED) {
                            val subscriptionManager = if (Build.VERSION.SDK_INT >= 22) this.getSystemService(SubscriptionManager::class.java) else null
                            if (subscriptionManager != null) {
                                val activeSubList = subscriptionManager.activeSubscriptionInfoList
                                if (activeSubList != null) {
                                    val sim1 = activeSubList.find { it.simSlotIndex == 0 }
                                    if (sim1 != null) {
                                        targetSubId = sim1.subscriptionId
                                    }
                                }
                            }
                        }

                        val smsManager: SmsManager;
                        if (Build.VERSION.SDK_INT >= 31) {
                            val defaultSms = this.getSystemService(SmsManager::class.java)!!;
                            smsManager = if (targetSubId != -1) defaultSms.createForSubscriptionId(targetSubId) else defaultSms
                        } else {
                            smsManager = if (targetSubId != -1) SmsManager.getSmsManagerForSubscriptionId(targetSubId) else SmsManager.getDefault()
                        }
                        val parts = smsManager.divideMessage(msg)
                        smsManager.sendMultipartTextMessage(phone, null, parts, null, null)
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
