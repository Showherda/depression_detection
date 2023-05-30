import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ml_depression/Pages/FaceTestWidget.dart';
import 'package:ml_depression/Pages/HomeWidget.dart';
import 'package:ml_depression/Pages/StartupWidget.dart';
import 'package:ml_depression/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  Future<SharedPreferences> getPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ML Depression',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      home: FutureBuilder<SharedPreferences>(
        future: getPrefs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final prefs = snapshot.data!;
            return (prefs.getBool(didStartupKey) ?? false)
                ? HomeWidget(prefs)
                : const StartupWidget();
          }
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }
}
