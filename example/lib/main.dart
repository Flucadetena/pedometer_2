import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pedometer_plus/pedometer_plus.dart';

String formatDate(DateTime d) {
  return d.toString().substring(0, 19);
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Pedometer Example'),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _StepStatus(),
                Divider(
                  height: 50,
                ),
                _StepCount(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepCount extends StatefulWidget {
  @override
  _StepCountState createState() => _StepCountState();
}

class _StepCountState extends State<_StepCount> {
  final _pedometer = Pedometer();
  int _stepCounts = 0;
  int _streamedStepCountFromToday = 0;
  int _gettableStepCount = 0;

  @override
  void initState() {
    super.initState();

    _getStreamGettableStepCount();
    _getStreamStepCountFrom();
    _getStepCount();
  }

  void _getStreamGettableStepCount() async {
    final stepCountStream = _pedometer.stepCountStream();
    stepCountStream.listen(
      (step) {
        print('onGettableStepCount: $step');
        setState(() {
          _gettableStepCount = step;
        });
      },
    ).onError((error) {
      print('onGettableStepCountError: $error');
      print('onGettableStepCountError:Step Count not available');
      setState(() {
        _gettableStepCount = 0;
      });
    });
  }

  void _getStreamStepCountFrom() async {
    if (Platform.isIOS) {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      final stepCountStream = _pedometer.stepCountStreamFrom(
        from: todayStart,
      );

      stepCountStream.listen((step) {
        print('onStepCountToday: $step');
        setState(() {
          _streamedStepCountFromToday = step;
        });
      }).onError((error) {
        print('onStepCountTodayError: $error');
        print('onStepCountTodayError:Step Count not available');
        setState(() {
          _streamedStepCountFromToday = 0;
        });
      });
    } else if (Platform.isAndroid) {
      print('_getStreamStepCountFrom: Not available on Android');
    }
  }

  Future<void> _getStepCount() async {
    if (Platform.isIOS) {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      final stepCounts = await _pedometer.getStepCount(
        from: todayStart,
        to: DateTime.now(),
      );

      setState(() {
        _stepCounts = stepCounts;
      });
      print('_getStepCount: $_stepCounts');
    } else if (Platform.isAndroid) {
      print('_getStepCount: Not available on Android');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Stream Steps Taken',
          style: TextStyle(fontSize: 30),
        ),
        Text(
          _gettableStepCount.toString(),
          style: TextStyle(fontSize: 60),
        ),
        Divider(
          height: 10,
        ),
        Text(
          'Stream Steps Taken From Today',
          style: TextStyle(fontSize: 30),
        ),
        if (Platform.isIOS)
          Text(
            _streamedStepCountFromToday.toString(),
            style: TextStyle(fontSize: 60),
          )
        else if (Platform.isAndroid)
          Text(
            'Not available on Android',
            style: TextStyle(fontSize: 50),
          ),
        Divider(
          height: 10,
        ),
        Text(
          'Functional Steps Taken From Today',
          style: TextStyle(fontSize: 30),
        ),
        if (Platform.isIOS) ...[
          Text(
            _stepCounts.toString(),
            style: TextStyle(fontSize: 60),
          ),
          TextButton(
            onPressed: _getStepCount,
            child: Text('Get Step Count'),
          ),
        ] else if (Platform.isAndroid)
          Text(
            'Not available on Android',
            style: TextStyle(fontSize: 50),
          ),
      ],
    );
  }
}

class _StepStatus extends StatefulWidget {
  @override
  _StepStatusState createState() => _StepStatusState();
}

class _StepStatusState extends State<_StepStatus> {
  final _pedometer = Pedometer();

  StepStatus _status = StepStatus.unknown;

  @override
  void initState() {
    super.initState();

    final _stepStatusStream = _pedometer.stepStatusStream();
    _stepStatusStream.listen(onStepStatusChanged).onError(onStepStatusError);
  }

  void onStepStatusChanged(StepStatus status) {
    print('onStepStatusChanged: $status');
    setState(() {
      _status = status;
    });
  }

  void onStepStatusError(error) {
    print('onStepStatusError: $error');
    print('onStepStatusError: Pedestrian Status not available');
    setState(() {
      _status = StepStatus.unknown;
    });
    print("onStepStatusError:$_status");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Step Status',
          style: TextStyle(fontSize: 30),
        ),
        Icon(
          _status == StepStatus.walking
              ? Icons.directions_walk
              : _status == StepStatus.stopped
                  ? Icons.accessibility_new
                  : Icons.error,
          size: 100,
        ),
        Center(
          child: Text(
            _status.name,
            style:
                _status == StepStatus.walking || _status == StepStatus.stopped
                    ? TextStyle(fontSize: 30)
                    : TextStyle(fontSize: 20, color: Colors.red),
          ),
        )
      ],
    );
  }
}
