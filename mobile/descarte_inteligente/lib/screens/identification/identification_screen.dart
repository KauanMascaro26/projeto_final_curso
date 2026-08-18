import 'package:flutter/material.dart';

class IdentificationScreen extends StatelessWidget {
  const IdentificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identificar resíduo'),
      ),
      body: const Center(
        child: Text(
          'Identificação de resíduos',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}