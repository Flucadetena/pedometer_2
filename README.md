# Pedometer

<!-- [![pub package](https://img.shields.io/pub/v/pedometer.svg)](https://pub.dartlang.org/packages/pedometer) -->

This plugin allows for continuous step counting and pedestrian status using the built-in pedometer sensor API of iOS and Android devices.

<img height="500px" src="https://github.com/akaboshinit/pedometer_plus/raw/main/images/example.png"/>

Examples of the StepStatusStream screen on iOS.

## Platform support

✅ supported

❔ supported, but not tested locally.

❌ not supported

| Feature                                                              | Android | iOS |
| ------------------------------                                       | :-----: | :-: |
| stepStatusStream                                                     | ❔      | ✅  |
| stepCountStream (All steps taken from the system.)                   | ✅      | ✅  |
| stepCountStreamFrom (Steps since the stipulated date)                | ❌      | ✅  |
| getStepCount (Number of steps between specified beginning and end.)  | ❌      | ✅  |

## Permissions

For Android 10 and above add the following permission to the Android manifest:

```xml
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
```

For iOS, add the following entries to your Info.plist file in the Runner xcode project:

```xml
<key>NSMotionUsageDescription</key>
<string>This application tracks your steps</string>
```

## Step Count

The step count represents the number of steps taken since the last system boot.
On Android, any steps taken before installing the application will not be counted.

## Pedestrian Status

The Pedestrian status is either `walking` or `stopped`. In the case that of an error,
the status will be `unknown`.

## Availability of Sensors

Both Step Count and Pedestrian Status may not be available on some phones:

* It was found that some Samsung phones do not support Step Count or Pedestrian Status
* Older iPhones do not support Pedestrian Status in particular

In the case that the step sensor is not available, an error will be thrown. The application needs to handle this error.


Forked packages
- https://github.com/cph-cachet/flutter-plugins/tree/master/packages/pedometer

Inspired packages
- https://github.com/santa112358/simple_pedometer
