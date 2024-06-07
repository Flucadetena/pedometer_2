# Pedometer_2

*Base on Pedometer & Pedometer_plus (references at the bottom)

This plugin allows to get this info in both Android and IOS:  
- Get step count "from:to" specific dates
- Get step count since last system boot
- Get real time step count (Stream)
- Get real time pedestrian status: Awaking, Stopped (Stream)
- Get real time step count since a date (Stream) (Only on IOS)  
  **Alternative for Android explained under*

> **Yes all of this is supported in both Android and IOS*  
> **It uses the Sensors API (on Android & IOS) and the Recording API (Android).*

<img height="500px" src="https://github.com/Flucadetena/pedometer_2/raw/main/assets/example_preview.png"/>

## Configuration

### Permissions

For both Android and IOS you need to use request permission to track users activity.
I recommend using the package [Permission_handler](https://pub.dev/packages/permission_handler), but you can use others if it suits you best.

Using Permission handler (adapt as need for yours) you need to:

<details open>
  <summary><b>IOS</b></summary>

1. In your `Info.plist`, located under `ios>Runner`, add this:

   ```xml
   <key>NSMotionUsageDescription</key>
   <string>This application tracks your steps</string>
   ```

2. In your `Podfile`, located under the `ios` folder, add this:

   ```rb
    post_install do |installer|
        installer.pods_project.targets.each do |target|
            flutter_additional_ios_build_settings(target)

            ## ADD THIS SECTION
            target.build_configurations.each do |config|
                config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
                '$(inherited)',
                ## dart: PermissionGroup.sensors
                'PERMISSION_SENSORS=1',
                ]
            end
            ## END OF WHAT YOU NEED TO ADD
        end
    end
   ```

   *If you already have a `target.build_configurations.each do |config|` loop on your `Podfile`, you need to only include the `config.build_settings` section inside the loop.
   **Also if you are already using the *Permission_handler* plugin, simply ensure the `PERMISSION_SENSORS` is set to `1` instead of `0`.

</details>

<details open>
  <summary><b>ANDROID</b></summary>

- No need to include "ACTIVITY_RECOGNITION" in your Android manifest. It will be added on build
- It requires Android 10 (minSDK lvl 29)
- Make sure to support Android X _(If your project is not very very old, this is already enabled)_

</details>
  
  <!-- //! Request Permissions -->
## How to Use it
1. <details open>  
   <summary><b>Get Step count</b></summary>

    - You can request the total amount of steps taken by the user in an specific time period (from/to).
    - If `from` or `to` is not proportioned it defaults to the max amount of days recorded. In IOS is 7 days, in Android is 10.
    - If `from:to` range is higher than the maximum number of days recorded in each platform, the number of steps will represent only the max number recorded. Meaning, if `from:to` range represents the last 20 days, the number returned will actually only represent 7 days in IOS and 10 days in Android.
        #### Behavior
    - The first time you request tracking the users Activity after installing the app it will return `0`, as the phone starts recording since the app is installed and has requested permission.
    *(This means that if you uninstall and reinstall the app, the steps count will also return `0` the first time).*
    - This number will be the exact same, or almost, as the Google Fit app/ Health APP (Android/IOS). *(In tests shows more consistency than the Fit API on Android and does not require a Google Account or connection to the Health API in IOS).*
        #### Example:
        ```dart
        DateTime now = DateTime.now();
        // Start of the week - Monday
        DateTime from = now.subtract(Duration(days: now.weekday - 1));
        //End of the week - Sunday
        DateTime to = now.add(Duration(days: DateTime.daysPerWeek - now.weekday));

        int steps = await Pedometer().getStepCount(from: from, to: to);
        print('steps: $steps');
        ```
    </details>

2. <details open>  
    <summary><b>Get real time step count (Stream) & Steps since last system boot</b></summary>

    - When called it will first return the steps recorded since the last system boot. If the user moves it will keep streaming the updated number of steps.
    - If the number of steps is `0` it wont fire the stream until the user starts walking.
        #### Behavior
    - As with the `getStepCount` call, the first time you request tracking the users Activity after installing the app the value will be `0`. But unlike the `getStepCount` call, if the phone is turned off, when called again the value will be `0` again.
    - Also if the user changes the date of the phone manually it will also reset the step count to `0`.
        #### Example:
        ````dart
        StreamSubscription? _subStepCount;

        @override
        void initState() {
            super.initState();
            _listenToSteps();
        }

        @override
        void dispose() {
            // Don't forget to close the stream
            _subStepCount?.cancel();
            super.dispose();
        }

        _listenToSteps() {
            _subStepCount = Pedometer().stepCountStream().listen((steps) => print('Steps: $steps'));
        }
        ````
    </details>

3. <details open>  
    <summary><b>Get real time pedestrian status: Awaking, Stopped (Stream)</b></summary>

    - When called it will return the current pedestrian status, either `stopped` or `walking`. In case of an error it will return `unknown`.
        #### Behavior
    - When the stream is initialized it may not fire a result until the status changes. So assume the user is stopped from start as it will fire every 1/2 seconds.
        #### Example:
        ````dart
        StreamSubscription? _subStepStatus;

        @override
        void initState() {
            super.initState();
            _listenToStatus();
        }

        @override
        void dispose() {
            _subStepStatus?.cancel();
            super.dispose();
        }

        _listenToStatus() {
            _subStepStatus = Pedometer().stepStatusStream().listen((status) => print('Status: $status'));
        }
        ````
    </details>

4. <details open>  
    <summary><b>[IOS] Get real time step count since a date (Stream)</b></summary>
    
    - ***[Android alternative]** Use a combination of the `getStepCount` and `stepCountStream`.*
    
    - It will return the total amount of steps taken by the user `from` a specific date to `now()`, and then keep streaming as the number of steps increase.
        #### Behavior
    - It behaves as the `stepCountStream`, so the first is called the value will be `0` as it won't start recording until you have permission. If the value is `0` it may not fire until the user starts walking.
    - As with `getStepCount` the max. number of days recorded is 7, so if `from` date is earlier the value returned will only represent the past 7 days.
        #### Example:
        ````dart
        StreamSubscription? _subStepFrom;

        @override
        void initState() {
            super.initState();
            _listenToSteps();
        }

        @override
        void dispose() {
            _subStepFrom?.cancel();
            super.dispose();
        }

        _listenToSteps() {
            DateTime now = DateTime.now();
            // Start of the week - Monday
            DateTime from = now.subtract(Duration(days: now.weekday - 1));
            _subStepFrom = Pedometer().stepCountStreamFrom(from: from).listen((steps) => print('Steps: $steps'));
        }
        ````
    </details>

## Things to consider

The APIs used may not be available in some phones or may behave in different ways. Ex:

- It was found that some Samsung phones do not support the Sensors API.
- Older iPhones do not support Pedestrian Status in particular
- Manufacturers use different sensors and variation of the OS, this will result in Steps being measured in very different ways. *(This obviously applies mainly to Android)*

In the case that the step sensor is not available, an error will be thrown. The application needs to handle this error.

## Thanks and credits

### This package was originally forked from:

- [Pedometer_plus](https://pub.dev/packages/pedometer_plus) by [akaboshinit.dev](https://pub.dev/publishers/akaboshinit.dev/packages)

***_Which was originally forked and inspired by:_**

- [Pedometer](https://pub.dev/packages/pedometer) by [cachet.dk](https://pub.dev/publishers/cachet.dk/packages)
- [Simple_pedometer](https://pub.dev/packages/simple_pedometer) by [bookm.me](https://pub.dev/publishers/bookm.me/packages)

## Package Status

| Pub v.|Points| Popularity| Issues| Pull requests|
|-|-|-|-|-|
| [![pub package](https://img.shields.io/pub/v/animations.svg)](https://pub.dartlang.org/packages/pedometer_2) | [![pub points](https://img.shields.io/pub/points/animations)](https://pub.dartlang.org/packages/pedometer_2/score) | [![popularity](https://img.shields.io/pub/popularity/animations)](https://pub.dartlang.org/packages/pedometer_2/score) | [![GitHub issues](https://img.shields.io/github/issues/Flucadetena/pedometer_2)](https://github.com/Flucadetena/pedometer_2/issues) | [![GitHub pull requests](https://img.shields.io/github/issues-pr/Flucadetena/pedometer_2)](https://github.com/Flucadetena/pedometer_2/pulls) |
