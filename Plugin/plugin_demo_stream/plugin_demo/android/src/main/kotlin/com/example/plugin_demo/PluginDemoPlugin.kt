package com.example.plugin_demo

import android.app.Activity
import android.os.Handler
import android.util.Log
import android.widget.Toast
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** PluginDemoPlugin */
class PluginDemoPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    EventChannel.StreamHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    private var activity: Activity? = null
    private lateinit var call: MethodCall
    private lateinit var result: Result

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "plugin_demo")
        channel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "event_channel")
        eventChannel?.setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
        for(i in 0..10) {
            Thread.sleep(1000)
            this.eventSink?.success("$i")
        }
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
        this.eventChannel = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        this.call = call
        this.result = result
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }

            "getNativeAlert" -> {
                Toast.makeText(activity, "Hello from native", Toast.LENGTH_LONG).show()
            }

            "sum" -> {
                sum()
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun sum() {
//        Thread.sleep(2000)
//        val ints = call.arguments as List<Int>
//        result.success(ints[0] + ints[1])
        Thread(Runnable {
            Thread.sleep(2000)
            val ints = call.arguments as List<Int>
            result.success(ints[0] + ints[1])
            Log.i("Plugin", "result")
        }).start()
        Log.i("Plugin", "end sum")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
