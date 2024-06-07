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
  bool userIdle=false;
  final _windowFocusPlugin = WindowFocus();
  final _messangerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();

    _windowFocusPlugin.addFocusChangeListener((p0) {
      setState(() {
        activeWindowTitle='${p0.windowTitle}';
      });
    });
    _windowFocusPlugin.addUserActiveListener((p0) {
      setState(() {
        userIdle=p0;
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        scaffoldMessengerKey: _messangerKey,
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Window in focus plugin example app'),
          ),
          body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('Window title in focus: $activeWindowTitle\n'),
                  Text('User is idle: ${!userIdle}\n'),
                  TextButton(
                      onPressed: ()=>addInactivityThreshold(context),
                      child: Text('Add 5 seconds to the inactivity threshold')
                  )
                ],
              )
          ),
          bottomNavigationBar: TextButton(
            child: Text('Subscribe to my telegram channel @kotelnikoff_dev'),
            onPressed: ()async{
              if(await canLaunchUrl(Uri.parse('https://telegram.me/kotelnikoff_dev'))){
                await launchUrl(Uri.parse('https://telegram.me/kotelnikoff_dev'));
              }else{
                _messangerKey.currentState!.showSnackBar(
                    SnackBar(
                      content: Text('Oh! My Telegram Chanel @kotelnikoff_dev!'),
                    )
                );
              }
            }
          ),
        )
    );
  }
  void addInactivityThreshold(BuildContext context) async {
    try {
      Duration duration = await _windowFocusPlugin.idleThreshold;
      duration += const Duration(seconds: 5);
      _windowFocusPlugin.setIdleThreshold(duration: duration);

      _messangerKey.currentState!.showSnackBar(
          SnackBar(
            content: Text('Great! new inactivity threshold ${duration.inSeconds} seconds'),
          )
      );
    } catch (e, s) {
      print(e);
      print(s);
    }
  }
}

