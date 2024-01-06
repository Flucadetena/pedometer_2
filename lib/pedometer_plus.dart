import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';

class Pedometer {
  static const EventChannel _stepDetectionChannel =
      const EventChannel('step_detection');
  static const EventChannel _stepCountChannel =
      const EventChannel('step_count');

  static const MethodChannel _methodChannel =
      MethodChannel('dev.akaboshinit.pedometer_plus');
  static const EventChannel _eventChannel =
      const EventChannel('dev.akaboshinit.pedometer_plus.stream');

  static StreamController<StepStatus> _androidStepStatusController =
      StreamController.broadcast();

  /// Returns one step at a time.
  /// Events come every time a step is detected.
  Stream<StepStatus> stepStatusStream() {
    Stream<StepStatus> stream = _stepDetectionChannel
        .receiveBroadcastStream()
        .map((event) => StepStatus.values[event as int]);
    if (Platform.isAndroid) return _androidStream(stream);
    return stream;
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
      t = Timer(Duration(seconds: 2), () {
        _androidStepStatusController.add(StepStatus.stopped);
        stepStatus = StepStatus.stopped;
      });
    }, onError: (error) {
      _androidStepStatusController.addError(error);
    });

    return _androidStepStatusController.stream;
  }

  /// Returns the steps taken since last system boot.
  /// Events may come with a delay.
  Stream<int> stepCountStream() =>
      _stepCountChannel.receiveBroadcastStream().map((event) => event as int);

  Stream<int> stepCountStreamFrom({
    required DateTime from,
  }) {
    if (Platform.isAndroid) {
      throw UnsupportedError(
          'stepCountStreamFrom() is not supported on Android. Use stepCountStream instead.');
    }

    return _eventChannel.receiveBroadcastStream({
      'startTime': from.millisecondsSinceEpoch,
    }).map((event) => event as int);
  }

  Future<int> getStepCount({
    required DateTime from,
    required DateTime to,
  }) async {
    if (Platform.isAndroid) {
      throw UnsupportedError(
          'getStepCount() is not supported on Android. Use stepCountStream instead.');
    }

    final args = <String, dynamic>{
      'startTime': from.millisecondsSinceEpoch,
      'endTime': to.millisecondsSinceEpoch
    };
    final int steps = await _methodChannel.invokeMethod(
      'getStepCount',
      args,
    );
    return steps;
  }
}

enum StepStatus {
  stopped(statusCode: 0),
  walking(statusCode: 1),
  unknown(statusCode: 2);

  const StepStatus({required this.statusCode});

  final int statusCode;
}
