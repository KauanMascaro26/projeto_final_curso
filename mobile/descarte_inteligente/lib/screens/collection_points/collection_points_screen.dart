import 'package:flutter/material.dart';

class CollectionPointsScreen extends StatelessWidget {
  const CollectionPointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pontos de coleta'),
      ),
      body: const Center(
        child: Text(
          'Pontos de coleta próximos',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}