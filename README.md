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

For both Android and IOS you need to request permission to track users activity.
I recommend using the package [Permission_handler](https://pub.dev/packages/permission_handler), but you can use others if it suits you better.

Using Permission handler you need to: (adapt for other packages)

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

- No need to include "ACTIVITY_RECOGNITION" in your Android manifest. It will be added on build.
- It **requires Android 10 (minSDK lvl 29)**. Change this on your `build.gradle` located under `android>app>build.gradle`.
- This package uses the embedded **Kotlin version `1.9.10`**. This is either located on your `build.gradle` at the root of the `android` folder: `From this: [ext.kotlin_version = '1.7.10'] to this: [ext.kotlin_version = '1.9.10']`, or in new projects it may be located under `settings.gradle` at the root of the `android` folder: `From this: [id "org.jetbrains.kotlin.android" version "1.7.10" apply false] to this: [id "org.jetbrains.kotlin.android" version "1.9.10" apply false]`. If you have a different version you can try and see if there are no issue, but be aware you may have to change it. Mainly if it is an older version.
- Also you need to change **Gradle version**. This package uses the minimum compatible with this Kotlin version, **the `8.4`**. For this you need to update the `distributionUrl` in the file `gradle-wrapper.properties` under `android>gradle>wrapper>gradle-wrapper.properties`, and change your current url to this: `distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-all.zip`. If you need another version or would like to update to a newer one you can check the compatibility between versions here: [Compatibility Matrix](https://docs.gradle.org/current/userguide/compatibility.html)
- Make sure to support Android X _(If your project is not very very old, this is already enabled)_.

</details>
  
## How to Use it
1. <details open>  
   <summary><b>Request Permissions</b></summary>

    - Using the *Permission_handler* plugin, you can request permission for both platforms.
    - This plugin includes a very handy function to open the system setting for the app and make it easier for the user to change them in case the prompt is not shown.
        #### Behavior
    - The first time you request a permission to the user, a dialog should pop requesting access to the his activity. The following times the permission request will automatically return an answer based on the previous answer or the current setting of the app if the user has set them from the setting screen in the OS.
    - Take this into consideration to show the user a dialog of snackbar and request him to update the permissions.  
    **Please make sure the previous "Permissions" step has been implemented correctly as you may get false positives or negatives if not*
        #### Example:
        ```dart
        import 'package:permission_handler/permission_handler.dart';

        PermissionStatus perm = 
        Platform.isAndroid ? await Permission.activityRecognition.request() : await Permission.sensors.request();
        print('perm: $perm');
        
        if (perm.isDenied || perm.isPermanentlyDenied || perm.isRestricted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'You need to approve the permissions to use the pedometer',
                        style: TextStyle(
                        color: Theme.of(context).colorScheme.onError,
                        fontWeight: FontWeight.bold,
                        ),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.errorContainer,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(themeBorderRadius),
                    ),
                    // Open the system settings to allow the permissions
                    action: SnackBarAction(
                        label: 'Settings',
                        textColor: Theme.of(context).colorScheme.onError,
                        onPressed: () => openAppSettings(),
                    ),
                ),
            );
        } else {
            // Call the functions your need to read stepCount
        }
        ```
    </details>

2. <details open>  
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

3. <details open>  
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

4. <details open>  
    <summary><b>Get real time pedestrian status: Awaking, Stopped (Stream)</b></summary>

    - When called it will return the current pedestrian status, either `stopped` or `walking`. In case of an error it will return `unknown`.
        #### Behavior
    - When the stream is initialized it may not fire a result until the status changes. So assume the user is stopped from start as it will fire every 1/2 seconds.
        #### Example:
        ````dart
        StreamSubscription? _subPedestrianStatus;

        @override
        void initState() {
            super.initState();
            _listenToStatus();
        }

        @override
        void dispose() {
            _subPedestrianStatus?.cancel();
            super.dispose();
        }

        _listenToStatus() {
            _subPedestrianStatus = Pedometer().pedestrianStatusStream().listen((status) => print('Status: $status'));
        }
        ````
    </details>

5. <details open>  
    <summary><b>[IOS] Get real time step count since a date (Stream)</b></summary>
    
    - ***(Android alternative)** Use a combination of the `getStepCount` and `stepCountStream`. Example in the `Example App`*
    
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

***_The example app was inspired by [Purrweb Agency - Dribbble](https://dribbble.com/shots/22762014-Step-Counter-Mobile-iOS-App)_**

## Package Status & Contribute

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://buymeacoffee.com/f.lucadetena)


| Pub v.|Points| Popularity| Issues| Pull requests|
|-|-|-|-|-|
| [![pub package](https://img.shields.io/pub/v/animations.svg)](https://pub.dartlang.org/packages/pedometer_2) | [![pub points](https://img.shields.io/pub/points/animations)](https://pub.dartlang.org/packages/pedometer_2/score) | [![popularity](https://img.shields.io/pub/popularity/animations)](https://pub.dartlang.org/packages/pedometer_2/score) | [![GitHub issues](https://img.shields.io/github/issues/Flucadetena/pedometer_2)](https://github.com/Flucadetena/pedometer_2/issues) | [![GitHub pull requests](https://img.shields.io/github/issues-pr/Flucadetena/pedometer_2)](https://github.com/Flucadetena/pedometer_2/pulls) |
