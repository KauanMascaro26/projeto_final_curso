import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
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
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
