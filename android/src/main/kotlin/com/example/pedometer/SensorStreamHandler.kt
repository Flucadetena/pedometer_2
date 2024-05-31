package com.example.pedometer

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel

class SensorStreamHandler() : EventChannel.StreamHandler {

    private var sensorEventListener: SensorEventListener? = null
    private var sensorManager: SensorManager? = null
    private var sensor: Sensor? = null
    private lateinit var sensorName: String
    private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding


    constructor(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding, sensorType: Int) : this() {

        this.sensorName = if (sensorType == Sensor.TYPE_STEP_COUNTER) "StepCount" else "StepDetection"
        sensorManager = flutterPluginBinding.applicationContext.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        sensor = sensorManager!!.getDefaultSensor(sensorType)
        this.flutterPluginBinding = flutterPluginBinding
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        if (sensor == null) {
            events!!.error("1", "$sensorName not available", "$sensorName is not available on this device")
        } else {
            sensorEventListener = sensorEventListener(events!!)
            sensorManager!!.registerListener(sensorEventListener, sensor, SensorManager.SENSOR_DELAY_FASTEST)
        }
    }

    override fun onCancel(arguments: Any?) {
        sensorManager!!.unregisterListener(sensorEventListener)
    }
}
