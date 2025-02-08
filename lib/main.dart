import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pollutionmonitor/on_boarding/startup_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Automation',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: StartupView(),
    );
  }
}
