import 'package:flutter/material.dart';
import 'safe_her_welcome_screen.dart';
import 'login_screen.dart';

void main() {
  runApp(const SafeHerApp());
}

class SafeHerApp extends StatelessWidget {
  const SafeHerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeHer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SafeHerWelcomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}