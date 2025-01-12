import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:window_focus/window_focus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String activeWindowTitle = 'Unknown';
  bool userIdle = false;
  final _windowFocusPlugin = WindowFocus(debug: false,duration: const Duration(seconds: 5));
  final _messangerKey = GlobalKey<ScaffoldMessengerState>();
  DateTime? lastUpdateTime;
  final textController=TextEditingController();
  final idleTimeOutInSeconds=1;

  List<TimeAppDto> items = [];
  Duration allTime = const Duration();
  Duration idleTime = const Duration();
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    _windowFocusPlugin.addFocusChangeListener((p0) {
      print(p0);
      _handleFocusChange(p0.appName);
    });
    _windowFocusPlugin.addUserActiveListener((p0) {
      setState(() {
        userIdle = p0;
      });
    });
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateActiveAppTime();
      setState(() {
        allTime += const Duration(seconds: 1);

        if (!userIdle) {
          idleTime += const Duration(seconds: 1);
        }
      });
    });
  }

  void _updateActiveAppTime({bool forceUpdate = false}) {
    if (!userIdle) return;
    if (lastUpdateTime == null) return;


    final now = DateTime.now();
    final elapsed = now.difference(lastUpdateTime!);
    if (elapsed < const Duration(seconds: 1) && !forceUpdate) return;

    final existingIndex =
        items.indexWhere((item) => item.appName == activeWindowTitle);
    if (existingIndex != -1) {
      final existingItem = items[existingIndex];
      items[existingIndex] = existingItem.copyWith(
        timeUse: existingItem.timeUse + elapsed,
      );
      setState(() {

      });
    } else {
      items.add(TimeAppDto(appName: activeWindowTitle, timeUse: elapsed));
    }
    lastUpdateTime = now;
    setState(() {});
  }

  void _handleFocusChange(String newAppName) {
    final now = DateTime.now();

    if (activeWindowTitle != newAppName) {
      _updateActiveAppTime(forceUpdate: true);
    }
    activeWindowTitle = newAppName;
    lastUpdateTime = now;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        scaffoldMessengerKey: _messangerKey,
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Window in focus plugin example app'),
          ),
          body: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Window title in focus: $activeWindowTitle\n'),
                      Text('User is idle: ${!userIdle}\n'),
                      Text('Total Time: ${_formatDuration(allTime)}'),
                      const SizedBox(height: 10),
                      Text('Idle Time: ${_formatDuration(idleTime)}'),
                      const SizedBox(height: 10),
                      Text(
                          'Active Time: ${_formatDuration(allTime - idleTime)}'),
                      Form(
                          child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                  label: Text('Time in second')),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async{
                              Duration duration = await _windowFocusPlugin.idleThreshold;
                              print(duration);
                            },
                            child: const Text('Save timeOut'),
                          )
                        ],
                      ))
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(
                      Radius.circular(
                        24,
                      ),
                    ),
                  ),
                  child: ListView.builder(
                      itemBuilder: (context,index){
                        return ListTile(
                          title: Text(items[index].appName),
                          trailing: Text(formatDurationToHHMM(items[index].timeUse,)),
                        );
                      },
                    itemCount: items.length,
                  ),
                ),
              )
            ],
          ),
          bottomNavigationBar: TextButton(
              child: Text('Subscribe to my telegram channel @kotelnikoff_dev'),
              onPressed: () async {
                if (await canLaunchUrl(
                    Uri.parse('https://telegram.me/kotelnikoff_dev'))) {
                  await launchUrl(
                      Uri.parse('https://telegram.me/kotelnikoff_dev'));
                } else {
                  _messangerKey.currentState!.showSnackBar(const SnackBar(
                    content: Text('Oh! My Telegram Chanel @kotelnikoff_dev!'),
                  ));
                }
              }),
        ),
    );
  }

  void addInactivityThreshold(BuildContext context) async {
    try {
      Duration duration = await _windowFocusPlugin.idleThreshold;
      duration += const Duration(seconds: 5);
      _windowFocusPlugin.setIdleThreshold(duration: duration);

      _messangerKey.currentState!.showSnackBar(SnackBar(
        content: Text(
            'Great! new inactivity threshold ${duration.inSeconds} seconds'),
      ));
    } catch (e, s) {
      print(e);
      print(s);
    }
  }
  String formatDurationToHHMM(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }

  String _formatDuration(Duration duration) {
    return duration.toString().split('.').first.padLeft(8, "0");
  }

  @override
  void dispose() {
    _timer.cancel();
    _windowFocusPlugin.dispose();
    super.dispose();
  }
}

class TimeAppDto {
  final String appName;
  final Duration timeUse;

  TimeAppDto({required this.appName, required this.timeUse});

  TimeAppDto copyWith({
    String? appName,
    Duration? timeUse,
  }) {
    return TimeAppDto(
      appName: appName ?? this.appName,
      timeUse: timeUse ?? this.timeUse,
    );
  }

  @override
  int get hashCode {
    return timeUse.hashCode^appName.hashCode;
  }

  @override
  bool operator ==(Object other) {
    return other is TimeAppDto && other.timeUse == timeUse && other.appName == appName;

  }
}
