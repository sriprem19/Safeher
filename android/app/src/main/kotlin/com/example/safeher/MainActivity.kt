package com.example.safeher

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.telephony.SmsManager
import android.os.Build
import android.util.Log
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.safeher/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sendSms" -> {
                        val phone: String? = call.argument("phone")
                        val message: String? = call.argument("message")
                        
                        Log.d("SafeHer", "SMS Request - Phone: $phone, Message length: ${message?.length}")
                        
                        if (phone.isNullOrBlank() || message.isNullOrBlank()) {
                            Log.e("SafeHer", "Invalid arguments: phone or message is empty")
                            result.error("INVALID_ARGS", "Phone or message is empty", null)
                            return@setMethodCallHandler
                        }
                        
                        // Check SMS permission
                        if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS) 
                            != PackageManager.PERMISSION_GRANTED) {
                            Log.e("SafeHer", "SMS permission not granted")
                            result.error("PERMISSION_DENIED", "SMS permission not granted", null)
                            return@setMethodCallHandler
                        }
                        
                        try {
                            // Clean phone number - remove +91 prefix for Indian numbers as SmsManager handles local format better
                            val cleanPhone = if (phone.startsWith("+91")) {
                                phone.substring(3)
                            } else {
                                phone
                            }
                            
                            Log.d("SafeHer", "Sending SMS to: $cleanPhone")
                            
                            val smsManager: SmsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                applicationContext.getSystemService(SmsManager::class.java)
                            } else {
                                @Suppress("DEPRECATION")
                                SmsManager.getDefault()
                            }
                            
                            // Split long messages if needed
                            val parts = smsManager.divideMessage(message)
                            if (parts.size == 1) {
                                smsManager.sendTextMessage(cleanPhone, null, message, null, null)
                            } else {
                                smsManager.sendMultipartTextMessage(cleanPhone, null, parts, null, null)
                            }
                            
                            Log.d("SafeHer", "SMS sent successfully to $cleanPhone")
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e("SafeHer", "SMS sending failed: ${e.message}", e)
                            result.error("SMS_FAILED", "Failed to send SMS: ${e.message}", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
