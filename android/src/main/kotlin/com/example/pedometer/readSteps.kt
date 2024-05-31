package com.example.pedometer

import android.content.ContentValues.TAG
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.fitness.FitnessLocal
import com.google.android.gms.fitness.LocalRecordingClient
import com.google.android.gms.fitness.data.LocalDataSet
import com.google.android.gms.fitness.data.LocalDataType
import com.google.android.gms.fitness.request.LocalDataReadRequest
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.tasks.await
import java.lang.Exception
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
    }
    localRecordingClient.subscribe(LocalDataType.TYPE_STEP_COUNT_DELTA)
            // Continue with Recording API functions
            // Subscribe to steps data
            .addOnSuccessListener {
                try {
                    val steps = runBlocking { readLocalSteps(startTime, endTime, localRecordingClient) }
                    result.success(steps)
                }catch (e: Exception){
                    result.error("1", "Error getting the step count", e)
                }
            }.addOnFailureListener { e ->
                result.error("3", "Unable to subscribe to the Local Type", e)
            }
}

@RequiresApi(Build.VERSION_CODES.O)
suspend fun readLocalSteps(startTime: ZonedDateTime, endTime: ZonedDateTime, localRecordingClient: LocalRecordingClient): Int {
    val readRequest = LocalDataReadRequest.Builder()
            // The data request can specify multiple data types to return,
            // effectively combining multiple data queries into one call.
            // This example demonstrates aggregating only one data type.
            .aggregate(LocalDataType.TYPE_STEP_COUNT_DELTA)
            // Analogous to a "Group By" in SQL, defines how data should be
            // aggregated. bucketByTime allows bucketing by time span.
            .bucketByTime(1, TimeUnit.DAYS).setTimeRange(startTime.toEpochSecond(), endTime.toEpochSecond(), TimeUnit.SECONDS).build()

    val response = localRecordingClient.readData(readRequest).await()
    val buckets = response.buckets
    Log.i(TAG, "buckets-Size: ${buckets.size}")
    Log.i(TAG, "buckets: $buckets")

    var steps = 0
    for (dataSet in buckets.flatMap { it.dataSets }) {
        steps += aggregatedSteps(dataSet)
        Log.i(TAG, "Aggregating steps: $steps")
    }
    return steps

    //! localRecordingClient.readData(readRequest).addOnSuccessListener { response ->
        // The aggregate query puts datasets into buckets, so flatten into a
        // single list of datasets.
        //var steps = 0
        //for (dataSet in response.buckets.flatMap { it.dataSets }) {
    //  steps += aggregatedSteps(dataSet)
    //      Log.i(TAG, "Aggregating steps: $steps")
    //  }
    //  return steps
    //  Log.i(TAG, "Total Steps: $steps")
    //}.addOnFailureListener { e ->
    //  Log.w(ContentValues.TAG, "There was an error reading data", e)
    // throw  E("3", "There was an error reading the data", e)
    //}
}

private fun aggregatedSteps(dataSet: LocalDataSet): Int {
    var steps: Int = 0
    for (dp in dataSet.dataPoints) {
        for (field in dp.dataType.fields) {
            steps += dp.getValue(field).asInt()
        }
    }
    return steps
}