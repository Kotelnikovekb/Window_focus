import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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
  final _windowFocusPlugin = WindowFocus(debug: true,duration: const Duration(seconds: 5));
  final _messangerKey = GlobalKey<ScaffoldMessengerState>();
  DateTime? lastUpdateTime;
  final textController=TextEditingController();
  final idleTimeOutInSeconds=1;

  List<TimeAppDto> items = [];
  Duration allTime = const Duration();
  Duration idleTime = const Duration();
  late Timer _timer;
  Uint8List? _screenshot;

  bool _autoScreenshot = false;
  bool _activeWindowOnly = false;
  int _screenshotInterval = 10;
  Timer? _screenshotTimer;
  String? _lastSavedPath;
  final List<String> _screenshotLogs = [];

  @override
  void initState() {
    super.initState();

    _windowFocusPlugin.addFocusChangeListener((p0) {
      _handleFocusChange(p0.appName);
    });
    _windowFocusPlugin.addUserActiveListener((p0) {
      print('>>>>${p0}');
      setState(() {
        userIdle = p0;
      });
    });
    _startTimer();
  }

  Future<void> _takeScreenshot() async {
    final hasPermission = await _windowFocusPlugin.checkScreenRecordingPermission();
    if (!hasPermission) {
      await _windowFocusPlugin.requestScreenRecordingPermission();
      _messangerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Please grant screen recording permission and try again')),
      );
      return;
    }

    final screenshot = await _windowFocusPlugin.takeScreenshot(activeWindowOnly: _activeWindowOnly);
    if (screenshot != null) {
      print('Screenshot captured, size: ${screenshot.length} bytes');
      setState(() {
        _screenshot = screenshot;
        final timestamp = DateFormat('HH:mm:ss').format(DateTime.now());
        _screenshotLogs.insert(0, '[$timestamp] Screenshot captured');
        if (_screenshotLogs.length > 20) _screenshotLogs.removeLast();
      });
      await _saveScreenshot(screenshot);
    } else {
      print('Screenshot capture returned null');
    }
  }

  Future<void> _saveScreenshot(Uint8List bytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final screenshotsDir = Directory(p.join(directory.path, 'window_focus_screenshots'));
      if (!await screenshotsDir.exists()) {
        await screenshotsDir.create(recursive: true);
      }

      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'screenshot_$timestamp.png';
      final filePath = p.join(screenshotsDir.path, fileName);

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      setState(() {
        _lastSavedPath = filePath;
      });
      print('Screenshot saved to: $filePath');
    } catch (e) {
      print('Error saving screenshot: $e');
    }
  }

  void _toggleAutoScreenshot(bool value) {
    setState(() {
      _autoScreenshot = value;
    });

    if (_autoScreenshot) {
      _screenshotTimer = Timer.periodic(Duration(seconds: _screenshotInterval), (timer) {
        _takeScreenshot();
      });
    } else {
      _screenshotTimer?.cancel();
      _screenshotTimer = null;
    }
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
          actions: [
            IconButton(
              onPressed: _takeScreenshot,
              icon: const Icon(Icons.camera_alt),
              tooltip: 'Take screenshot of active window',
            ),
          ],
        ),
        body: Column(
          children: [
            if (_screenshot != null)
              Column(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    padding: const EdgeInsets.all(8.0),
                    child: Image.memory(_screenshot!, fit: BoxFit.contain),
                  ),
                  if (_lastSavedPath != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'Last saved to: $_lastSavedPath',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
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
                          const Divider(),
                          SwitchListTile(
                            title: const Text('Auto Screenshot'),
                            subtitle: Text('Interval: $_screenshotInterval seconds'),
                            value: _autoScreenshot,
                            onChanged: _toggleAutoScreenshot,
                          ),
                          SwitchListTile(
                            title: const Text('Active Window Only'),
                            value: _activeWindowOnly,
                            onChanged: (value) {
                              setState(() {
                                _activeWindowOnly = value;
                              });
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                const Text('Interval: '),
                                Expanded(
                                  child: Slider(
                                    value: _screenshotInterval.toDouble(),
                                    min: 5,
                                    max: 60,
                                    divisions: 11,
                                    label: '$_screenshotInterval',
                                    onChanged: _autoScreenshot
                                        ? null
                                        : (value) {
                                            setState(() {
                                              _screenshotInterval = value.toInt();
                                            });
                                          },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(),
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
                                onPressed: () async {
                                  Duration duration =
                                      await _windowFocusPlugin.idleThreshold;
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
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('App Usage', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            margin: const EdgeInsets.only(right: 8, bottom: 8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(Radius.circular(24)),
                            ),
                            child: ListView.builder(
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(items[index].appName, style: const TextStyle(fontSize: 12)),
                                  trailing: Text(formatDurationToHHMM(items[index].timeUse), style: const TextStyle(fontSize: 12)),
                                  visualDensity: VisualDensity.compact,
                                );
                              },
                              itemCount: items.length,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Screenshot Logs', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            margin: const EdgeInsets.only(right: 8, bottom: 8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(Radius.circular(24)),
                            ),
                            child: ListView.builder(
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Text(
                                    _screenshotLogs[index],
                                    style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                                  ),
                                );
                              },
                              itemCount: _screenshotLogs.length,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
        bottomNavigationBar: TextButton(
            child:
                const Text('Subscribe to my telegram channel @kotelnikoff_dev'),
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
