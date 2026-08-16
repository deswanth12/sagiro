package com.deshu.sagiro.app

import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity: FlutterFragmentActivity() {
    private val SMS_CHANNEL = "com.deshu.sagiro.app/sms_stream"
    private var smsReceiver: SmsReceiver? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    smsReceiver = SmsReceiver(events)
                    val filter = IntentFilter("android.provider.Telephony.SMS_RECEIVED")
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        registerReceiver(smsReceiver, filter, RECEIVER_EXPORTED)
                    } else {
                        registerReceiver(smsReceiver, filter)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    smsReceiver?.let {
                        unregisterReceiver(it)
                        smsReceiver = null
                    }
                }
            }
        )
    }
}
