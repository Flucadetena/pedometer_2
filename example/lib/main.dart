import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:pedometer_2/pedometer_2.dart';
import 'package:pedometer_2_example/forms.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

const double themeBorderRadius = 8;
const double scaffoldPadding = 16;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.from(
        colorScheme: ColorScheme(
          primary: const Color(0xFFffe4e4),
          secondary: const Color(0xFFA768F7),
          tertiary: const Color(0xFFFEDE00),
          surface: const Color(0xFF000000),
          background: Colors.black,
          error: Theme.of(context).colorScheme.error,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Colors.white,
          onBackground: Colors.white,
          onError: Colors.white,
          brightness: Brightness.dark,
        ),
      ),
      home: const Scaffold(
        body: Home(),
      ),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final sizes = SquareSizes(MediaQuery.of(context).size.width);

    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(scaffoldPadding),
          child: Column(
            children: [
              const Text(
                'Example App',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Stack(
                children: [
                  const UserPreview(),
                  const StepData(),
                  Positioned(
                    top: sizes.stepDataHeight - sizes.gitSize,
                    child: const GitInfo(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StepData extends StatefulWidget {
  const StepData({super.key});

  @override
  State<StepData> createState() => _StepDataState();
}

class _StepDataState extends State<StepData> {
  int? stepCount;
  int? stepCountStream;
  PedestrianStatus? pedestrianStatusStream;

  /// Only for IOS out of the box.
  /// For android use a combination of getStepCount and stepCountStream. (Example code below)
  int? stepCountStreamFrom;
  // only used to show how to implement the streamFrom in android
  int? androidFirstStepFrom;

  StreamSubscription? _stepStream;
  StreamSubscription? _stepStreamFrom;
  StreamSubscription? _pedestrianStatusStream;

  DateTime now = DateTime.now();
  // Start of the week - Monday
  late DateTime from = now.subtract(Duration(days: now.weekday - 1));
  //End of the week - Sunday
  late DateTime to =
      now.add(Duration(days: DateTime.daysPerWeek - now.weekday));

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    super.dispose();
    _stepStream?.cancel();
    _stepStreamFrom?.cancel();
    _pedestrianStatusStream?.cancel();
  }

  void _checkPermissions() async {
    PermissionStatus perm = Platform.isAndroid
        ? await Permission.activityRecognition.request()
        : await Permission.sensors.request();

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
      _getStepCount();
      _listenStepCountStream();
      _listenStepCountStreamFrom();
      _listenPedestrianStatusStream();
    }
  }

  void _getStepCount() async {
    try {
      stepCount = await Pedometer().getStepCount(from: from, to: to);
      setState(() {});
    } catch (e) {
      throw Exception('getStepCount error: $e');
    }
  }

  void _listenStepCountStream() {
    try {
      _stepStream = Pedometer().stepCountStream().listen((step) {
        stepCountStream = step;
        setState(() {});
      });
    } catch (e) {
      throw Exception('stepCountStream error: $e');
    }
  }

  void _listenStepCountStreamFrom() async {
    try {
      if (Platform.isAndroid) {
        /// In android this call is not supported but you can mix the getStep and the stream.
        /// For this you need to save the first stepCount from the stream and subtract this plus the last steps amount registered
        /// and add the difference.
        stepCountStreamFrom =
            await Pedometer().getStepCount(from: from, to: DateTime.now());
        setState(() {});

        _stepStreamFrom = Pedometer().stepCountStream().listen((step) {
          if (androidFirstStepFrom == null) {
            // Like this you may lose some steps if the original count was 0.
            // You can improve this condition, this is just to show and example.
            androidFirstStepFrom = step;
            return;
          }

          stepCountStreamFrom =
              stepCountStreamFrom! + step - androidFirstStepFrom!;
          setState(() {});
        });
        return;
      }

      _stepStreamFrom =
          Pedometer().stepCountStreamFrom(from: from).listen((step) {
        stepCountStreamFrom = step;
        setState(() {});
      });
    } catch (e) {
      print('stepCountStreamFrom error: $e');
      throw Exception('stepCountStreamFrom error: $e');
    }
  }

  _listenPedestrianStatusStream() {
    try {
      _pedestrianStatusStream =
          Pedometer().pedestrianStatusStream().listen((status) {
        pedestrianStatusStream = status;
        setState(() {});
      });
    } catch (e) {
      throw Exception('pedestrianStatusStream error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = SquareSizes(MediaQuery.of(context).size.width);
    return CustomPaint(
      size: Size(sizes.stepDataWidth, sizes.stepDataHeight),
      painter: PedometerBigShape(color: Theme.of(context).colorScheme.primary),
      child: Container(
        padding: const EdgeInsets.all(8),
        height: sizes.stepDataHeight,
        width: sizes.stepDataWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: sizes.avatarHeight + 12),
            Text(
              'Pedometer_2',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Step Counting',
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w900,
                height: 1,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: sizes.avatarWidth - 16,
                  child: Column(
                    children: [
                      StepDataSquare(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onSecondary,
                        time: '${from.formatDate} - ${to.formatDate}',
                        name: 'GetCount',
                        functionName: 'getStepCount()',
                        value: stepCount.toString(),
                        stream: false,
                      ),
                      const SizedBox(height: 28),
                      AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          width: sizes.gitSize,
                          color: Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      StepDataSquare(
                        backgroundColor:
                            Theme.of(context).colorScheme.background,
                        foregroundColor:
                            Theme.of(context).colorScheme.onBackground,
                        name: 'Pedestrian Status',
                        functionName: 'pedestrianStatusStream()',
                        value: _enumToString(pedestrianStatusStream),
                        small: true,
                      ),
                      const SizedBox(height: 8),
                      StepDataSquare(
                        backgroundColor:
                            Theme.of(context).colorScheme.background,
                        foregroundColor:
                            Theme.of(context).colorScheme.onBackground,
                        time: 'Last boot - now',
                        name: 'Count',
                        functionName: 'stepCountStream()',
                        value: stepCountStream.toString(),
                      ),
                      const SizedBox(height: 8),
                      StepDataSquare(
                        backgroundColor:
                            Theme.of(context).colorScheme.background,
                        foregroundColor:
                            Theme.of(context).colorScheme.onBackground,
                        time: '${from.formatDate} - now',
                        name: 'CountFrom',
                        functionName: 'stepCountStreamFrom()',
                        value: stepCountStreamFrom.toString(),
                      ),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class StepDataSquare extends StatelessWidget {
  final Color backgroundColor;
  final Color foregroundColor;
  final String name;
  final String functionName;
  final bool small;
  final bool stream;
  final String? time;
  final String? value;

  const StepDataSquare({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.name,
    required this.functionName,
    required this.value,
    this.small = false,
    this.stream = true,
    this.time,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: small ? 150 / 60 : 150 / 90,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(themeBorderRadius),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (time case String time) ...{
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w400,
                        color: foregroundColor,
                      ),
                    ),
                  },
                  const SizedBox(height: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: small ? 10 : 16,
                            fontWeight: FontWeight.bold,
                            height: 1,
                            color: foregroundColor,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Opacity(
                          opacity: .8,
                          child: Text(
                            '  $functionName',
                            style: TextStyle(
                              fontSize: 6,
                              fontWeight: FontWeight.bold,
                              height: 1,
                              color: foregroundColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (value case String value)
                          Text(
                            value,
                            style: TextStyle(
                              fontSize: small ? 20 : 30,
                              fontWeight: FontWeight.w900,
                              height: 1,
                              color: foregroundColor,
                            ),
                          )
                        else
                          Container(
                            height: 14,
                            width: 14,
                            margin: const EdgeInsets.all(4),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: foregroundColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (stream)
              Opacity(
                opacity: .6,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'Stream',
                    style: TextStyle(
                      fontSize: small ? 10 : 16,
                      fontWeight: FontWeight.bold,
                      height: 1,
                      color: foregroundColor,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class UserPreview extends StatefulWidget {
  const UserPreview({super.key});

  @override
  State<UserPreview> createState() => _UserPreviewState();
}

class _UserPreviewState extends State<UserPreview> {
  String release = '-';
  @override
  void initState() {
    super.initState();
    _packageInfo();
  }

  _packageInfo() async {
    try {
      var response = await get(Uri.parse(
          'https://api.github.com/repos/Flucadetena/pedometer_2/releases/latest'));

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to get the release version. Status code: ${response.statusCode}');
      }

      release = jsonDecode(response.body)?['name'] ?? '-';
      setState(() {});
    } catch (e) {
      print('Error getting the release version: $e');
      throw Exception('Issues getting the release version: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = SquareSizes(MediaQuery.of(context).size.width);
    return CustomPaint(
      size: Size(sizes.avatarWidth, sizes.avatarHeight),
      painter: UserCustomPaint(color: Theme.of(context).colorScheme.primary),
      child: Container(
        width: sizes.avatarWidth,
        height: sizes.avatarHeight,
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Container(
              height: sizes.avatarHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(themeBorderRadius),
                image: const DecorationImage(
                  fit: BoxFit.contain,
                  image: NetworkImage(
                    'https://cdn.buymeacoffee.com/uploads/profile_pictures/2024/06/BgVFjaW0yGXeEvef.png@300w_0e.webp',
                  ),
                ),
              ),
              child: const AspectRatio(aspectRatio: 1),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'F.lucadetena',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Opacity(
                    opacity: .6,
                    child: Text(
                      release,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GitInfo extends StatefulWidget {
  const GitInfo({super.key});

  @override
  State<GitInfo> createState() => _GitInfoState();
}

class _GitInfoState extends State<GitInfo> {
  int? issues;
  int? pulls;

  @override
  void initState() {
    super.initState();
    _loadGithubData();
  }

  _loadGithubData() async {
    try {
      var response = await get(Uri.parse(
          'https://api.github.com/search/issues?q=repo:Flucadetena/pedometer_2+type:issue&page=0&per_page=1'));

      if (response.statusCode != 200)
        throw Exception(
            'Failed to get issues. Status code: ${response.statusCode}');

      issues = jsonDecode(response.body)?['total_count'] ?? 0;
    } catch (e) {
      print('Error getting issues: $e');
      throw Exception('Issues error: $e');
    }

    try {
      var response = await get(Uri.parse(
          'https://api.github.com/search/issues?q=repo:Flucadetena/pedometer_2+type:pr&page=0&per_page=1'));
      if (response.statusCode != 200)
        throw Exception(
            'Failed to get pulls. Status code: ${response.statusCode}');

      pulls = jsonDecode(response.body)?['total_count'] ?? 0;
    } catch (e) {
      print('Error getting pulls: $e');
      throw Exception('Pulls error: $e');
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sizes = SquareSizes(MediaQuery.of(context).size.width);
    return GestureDetector(
      onTap: () {
        /**
         * Thanks for contributing in any way to this project.
         * Github details:
         * - Open a new issue: https://github.com/Flucadetena/pedometer_2/issues
         * - Create/Check a PullRequest: https://github.com/Flucadetena/pedometer_2/pulls
         * - Request a feature or ask for help: https://github.com/Flucadetena/pedometer_2/discussions
         * 
         * Buy me a coffee. There is no need but if you insist I'll be more than grateful,
         * this helps me to keep working on this project:
         * Link: https://buymeacoffee.com/f.lucadetena
         **/
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Github details on the code',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onTertiary,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(themeBorderRadius),
            ),
          ),
        );
      },
      child: Stack(
        children: [
          CustomPaint(
            size: Size(sizes.gitSize, sizes.gitSize),
            painter: PedometerGitShape(),
            child: Container(
              width: sizes.gitSize,
              height: sizes.gitSize,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: sizes.gitSize * .06),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(.8),
                      borderRadius: BorderRadius.circular(themeBorderRadius),
                    ),
                    child: Text(
                      'Buy me a coffee',
                      style: TextStyle(
                        fontSize: 8,
                        height: 1,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.background,
                      ),
                    ),
                  ),
                  SizedBox(height: sizes.gitSize * .18),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Issue & Request',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        const Spacer(),
                        GitData(
                          label: 'Issues',
                          number: issues,
                        ),
                        GitData(
                          label: 'Pulls',
                          number: pulls,
                        ),
                        const Spacer(),
                        IgnorePointer(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onBackground,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(themeBorderRadius),
                              ),
                            ),
                            icon: const Text('Create new'),
                            label: const Icon(
                              Icons.open_in_new_rounded,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: Container(
              height: sizes.gitSize * .335,
              width: sizes.gitSize * .35,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                borderRadius: BorderRadius.circular(themeBorderRadius),
                image: const DecorationImage(
                  image: NetworkImage(
                      'https://i.giphy.com/media/v1.Y2lkPTc5MGI3NjExejU0dWEzems0eXYyY2RtaDM1djE5M3BqMzhnMjVxcmdldGdwbjZlOSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/TDQOtnWgsBx99cNoyH/giphy.gif'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GitData extends StatelessWidget {
  final String label;
  final int? number;
  const GitData({required this.label, required this.number, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Opacity(
          opacity: .7,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              height: 1,
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 2),
        if (number case int number)
          Expanded(
            child: Text(
              number.toString(),
              style: TextStyle(
                fontSize: 14,
                height: 1,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          )
        else
          Container(
            height: 6,
            width: 6,
            margin: const EdgeInsets.all(4),
            child: CircularProgressIndicator(
              strokeWidth: 1,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
      ],
    );
  }
}

class SquareSizes {
  late final double _width;

  SquareSizes(double width) {
    _width = width - scaffoldPadding * 2;
  }

  double get avatarWidth => _width * .50;
  double get avatarHeight => avatarWidth * .31;
  double get stepDataWidth => _width;
  double get stepDataHeight => stepDataWidth * 1.24;
  double get gitSize => _width * .45;
}

extension DateTimeExtension on DateTime {
  String get formatDate {
    final day = this.day.formatNumber;
    final month = this.month.formatNumber;
    return '$day.$month';
  }
}

extension IntExtension on int {
  String get formatNumber {
    return toString().padLeft(2, '0');
  }
}

String? _enumToString(Object? o) => o?.toString().split('.').last;
