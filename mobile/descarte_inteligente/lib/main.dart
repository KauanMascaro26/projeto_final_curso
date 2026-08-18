import 'package:flutter/material.dart';

import 'screens/home/home_screen.dart';

void main() {
  runApp(const DescarteInteligenteApp());
}

class DescarteInteligenteApp extends StatelessWidget {
  const DescarteInteligenteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Descarte Inteligente',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: const HomeScreen(),
    );
  }
}