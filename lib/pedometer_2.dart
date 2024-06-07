import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pedometer_2/helpers.dart';

enum StepStatus {
  stopped,
  walking,
  unknown,
}

enum PedometerMethods {
  getStepCount,
}

class Pedometer {
 /// The [EventChannel] for StepStatus events.
  static EventChannel statusDetectionChannel = const EventChannel('status_detection');

  /// The [EventChannel] for step count events.
  static  EventChannel stepCountChannel = const EventChannel('step_count');

  /// The [EventChannel] for the IOS step count from X date events.
  static  EventChannel stepCountFromChannel = const EventChannel('step_count_from');

  /// MethodChannel to handle all "OneTime" calls. Currently only used for 'getStepCount'.
  static  MethodChannel methodChannel = const MethodChannel('method_channel');

  /// A stream controller for tracking step status on Android.
  static final StreamController<StepStatus> _androidStepStatusController = StreamController.broadcast();

  /// Returns a stream of [StepStatus] representing the status of steps.
  ///
  /// The stream emits [StepStatus] values based on the step detection events received from the platform.
  /// Events are fired every time a step is detected.
  /// On Android, the stream is processed by [_androidStream] before being returned.
  ///
  /// Example usage:
  /// ```dart
  /// Pedometer pedometer = Pedometer();
  /// Stream<StepStatus> statusStream = pedometer.stepStatusStream();
  /// statusStream.listen((status) {
  ///   print('Step status: $status');
  /// });
  /// ```
  Stream<StepStatus> stepStatusStream() {
    try {
      Stream<StepStatus> stream =
          statusDetectionChannel.receiveBroadcastStream().map((event) => StepStatus.values[event as int]);
      if (Platform.isAndroid) return _androidStream(stream);
      return stream;
    } catch (e) {
      throw ErrorSummary('Error on stepStatusStream: $e');
    }
  }

  /// Returns a stream of the number of steps taken since the last system boot.
  ///
  /// The events emitted by this stream may come with a delay.
  ///
  /// The first time this stream is called the value of steps may be 0
  /// and the stream won't emit any events until the user takes a step. Every event
  /// returns the total number of steps taken since the last system boot. Not since
  /// the listener was added.
  ///
  /// Example usage:
  /// ```dart
  /// Pedometer pedometer = Pedometer();
  /// Stream<int> stepCountStream = pedometer.stepCountStream();
  ///
  /// stepCountStream.listen((stepCount) {
  ///   print('Number of steps taken: $stepCount');
  /// });
  /// ```
  Stream<int> stepCountStream() {
    try {
      return stepCountChannel.receiveBroadcastStream().map((event) => event as int);
    } catch (e) {
      throw ErrorSummary('Error on StepCountStream: $e');
    }
  }

  /// Returns a stream of steps count starting [from] date.
  ///
  /// On Android, this method is not supported. Instead, use a combination of the
  /// [getStepCount()] and [StepCountStream()] methods.
  ///
  /// The [from] parameter specifies the starting date and time from which to retrieve
  /// the step counts.
  ///
  /// Example usage:
  /// ```dart
  /// Pedometer pedometer = Pedometer();
  /// DateTime fromDate = DateTime.now().subtract(Duration(days: 7));
  /// Stream<int> stepCountStream = pedometer.stepCountStreamFrom(from: fromDate);
  ///
  /// stepCountStream.listen((stepCount) {
  ///   print('Step count from $fromDate: $stepCount');
  /// });
  /// ```
  Stream<int> stepCountStreamFrom({
    required DateTime from,
  }) {
    if (Platform.isAndroid) {
      throw UnsupportedError(
          'stepCountStreamFrom() is not supported on Android. Use a combination of "getStepCount()" and "StepCountStream()"');
    }
    try {
      return stepCountFromChannel
          .receiveBroadcastStream({'startTime': from.millisecondsSinceEpoch}).map((event) => event as int);
    } catch (e) {
      throw ErrorSummary('Error on StepCountStreamFrom: $e');
    }
  }

  /// Retrieves the steps count within a specified time range.
  ///
  /// The [from] parameter specifies the starting date and time of the time range.
  /// The [to] parameter specifies the ending date and time of the time range.
  /// If [from] is not provided, it defaults to 10 days before [to].
  /// If [to] is not provided, it defaults to the current date and time.
  ///
  /// Throws an assertion error if [from] is after [to].
  ///
  /// In IOs the maximum number of days the system saves the step count is 7.
  /// In Android the maximum number of days the system saves the step count is 10.
  /// If the time range is greater than the maximum number of days for each platform,
  /// the system will return all the steps saved (but will only represent 7/10 days).
  ///
  /// Example usage:
  /// ```dart
  /// Pedometer pedometer = Pedometer();
  /// DateTime fromDate = DateTime.now().subtract(Duration(days: 5));
  /// DateTime toDate = DateTime.now();
  /// int stepCount = await pedometer.getStepCount(from: fromDate, to: toDate);
  /// print('Step count from $fromDate to $toDate: $stepCount');
  /// ```
  Future<int> getStepCount({DateTime? from, DateTime? to}) async {
    assert(!(from != null && to != null && from.compareTo(to) > 0), "From must be before to");
    try {
      to ??= DateTime.now();
      from ??= to.subtract(const Duration(days: 10));

      final args = {'startTime': from.millisecondsSinceEpoch, 'endTime': to.millisecondsSinceEpoch};
      final int steps = await methodChannel.invokeMethod(enumToString(PedometerMethods.getStepCount), args);

      return steps;
    } catch (e) {
      throw ErrorSummary('Error getting step count: $e');
    }
  }

  /// Transformed stream for the Android platform
  static Stream<StepStatus> _androidStream(Stream<StepStatus> stream) {
    /// Init a timer and a status
    Timer? t;
    StepStatus? stepStatus;

    /// Listen for events on the original stream
    /// Transform these events by using the timer
    stream.listen((_) {
      /// If an event is received it means the status is 'walking'
      /// If the timer has been started, it should be cancelled
      /// to prevent sending out additional 'walking' events
      if (t != null) {
        t!.cancel();

        /// If a previous status was either not set yet, or was 'stopped'
        /// then a 'walking' event should be emitted.
        if (stepStatus == null || stepStatus == StepStatus.stopped) {
          _androidStepStatusController.add(StepStatus.walking);
          stepStatus = StepStatus.walking;
        }
      }

      /// After receiving an event, start a timer for 2 seconds, after
      /// which a 'stopped' event is emitted. If it manages to go through,
      /// it is because no events were received for the 2 second duration
      t = Timer(const Duration(seconds: 2), () {
        _androidStepStatusController.add(StepStatus.stopped);
        stepStatus = StepStatus.stopped;
      });
    }, onError: (error) {
      _androidStepStatusController.addError(error);
    });

    return _androidStepStatusController.stream;
  }
}
