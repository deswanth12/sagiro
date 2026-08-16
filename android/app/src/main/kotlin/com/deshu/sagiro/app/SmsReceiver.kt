package com.deshu.sagiro.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.telephony.SmsMessage
import io.flutter.plugin.common.EventChannel

class SmsReceiver(private var eventSink: EventChannel.EventSink? = null) : BroadcastReceiver() {
    constructor() : this(null)
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == "android.provider.Telephony.SMS_RECEIVED") {
            val bundle = intent.extras
            if (bundle != null) {
                val pdus = bundle.get("pdus") as Array<*>?
                if (pdus != null) {
                    for (pdu in pdus) {
                        val format = bundle.getString("format")
                        val sms = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            SmsMessage.createFromPdu(pdu as ByteArray, format)
                        } else {
                            @Suppress("DEPRECATION")
                            SmsMessage.createFromPdu(pdu as ByteArray)
                        }
                        
                        val map = HashMap<String, Any?>()
                        map["address"] = sms.originatingAddress
                        map["body"] = sms.messageBody
                        map["date"] = sms.timestampMillis

                        eventSink?.success(map)
                    }
                }
            }
        }
    }
}
