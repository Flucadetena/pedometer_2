package com.example.pedometer_2

import android.Manifest
import android.content.ContentValues.TAG
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.fitness.FitnessLocal
import com.google.android.gms.fitness.LocalRecordingClient
import com.google.android.gms.fitness.data.LocalDataSet
import com.google.android.gms.fitness.data.LocalDataType
import com.google.android.gms.fitness.request.LocalDataReadRequest
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.async
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.tasks.await
import java.time.ZonedDateTime
import java.util.concurrent.TimeUnit

@RequiresApi(Build.VERSION_CODES.O)
fun getSteps(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding, startTime: ZonedDateTime, endTime: ZonedDateTime, result: MethodChannel.Result) {

    val context = flutterPluginBinding.applicationContext
    val localRecordingClient: LocalRecordingClient = FitnessLocal.getLocalRecordingClient(context)
    val hasMinPlayServices: Int = GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(context, LocalRecordingClient.LOCAL_RECORDING_CLIENT_MIN_VERSION_CODE)

    if (hasMinPlayServices != ConnectionResult.SUCCESS) {
        // Prompt user to update their device's Google Play services app and return
        result.error("2", "Min playService version error", "${LocalRecordingClient.LOCAL_RECORDING_CLIENT_MIN_VERSION_CODE} is required, but found a lower version")
        return
    }

    Log.d(TAG, "ActivityCompat: ${ActivityCompat.checkSelfPermission(context, Manifest.permission.ACTIVITY_RECOGNITION)}")
    if (ActivityCompat.checkSelfPermission(context, Manifest.permission.ACTIVITY_RECOGNITION) != PackageManager.PERMISSION_GRANTED) {
        result.error("2", "Permissions have not been requested", Exception())
        return
    }
    Log.d(TAG, "localRecordingClient:")
    localRecordingClient.subscribe(LocalDataType.TYPE_STEP_COUNT_DELTA)
            // Continue with Recording API functions
            // Subscribe to steps data
            .addOnSuccessListener {
                try {
                    Log.d(TAG, "addOnSuccessListener:")
                    val deferred = GlobalScope.async { readLocalSteps(startTime, endTime, localRecordingClient) }

                    // Later, when you need the result:
                    val steps = runBlocking { deferred.await() }
                    Log.d(TAG, "result: $steps")
                    result.success(steps)
                }catch (e: Exception){
                    Log.d(TAG, "catch: $e")
                    result.error("1", "Error getting the step count", e)
                }
            }.addOnFailureListener { e ->
                Log.d(TAG, "addOnFailureListener: $e")
                result.error("3", "Unable to subscribe to the Local Type", e)
            }
}

@RequiresApi(Build.VERSION_CODES.O)
suspend fun readLocalSteps(startTime: ZonedDateTime, endTime: ZonedDateTime, localRecordingClient: LocalRecordingClient): Int {
    Log.d(TAG, "readRequest:")
    val readRequest = LocalDataReadRequest.Builder()
            .aggregate(LocalDataType.TYPE_STEP_COUNT_DELTA)
            .bucketByTime(1, TimeUnit.DAYS).setTimeRange(startTime.toEpochSecond(), endTime.toEpochSecond(), TimeUnit.SECONDS).build()
    Log.d(TAG, "readRequest: $readRequest")

    val response = localRecordingClient.readData(readRequest).await()
    Log.d(TAG, "readLocalSteps: $response")
    val buckets = response.buckets
    Log.i(TAG, "buckets-Size: ${buckets.size}")


    var steps = 0
    for (dataSet in buckets.flatMap { it.dataSets }) {
        steps += aggregatedSteps(dataSet)
    }
    Log.d(TAG, "readLocalSteps: $steps")
    return steps
}

private fun aggregatedSteps(dataSet: LocalDataSet): Int {
    Log.d(TAG, "aggregatedSteps:")
    var steps = 0
    Log.d(TAG, "aggregatedSteps-steps/0: $steps")
    for (dp in dataSet.dataPoints) {
        for (field in dp.dataType.fields) {
            steps += dp.getValue(field).asInt()
        }
    }
    Log.d(TAG, "aggregatedSteps-res: $steps")
    return steps
}