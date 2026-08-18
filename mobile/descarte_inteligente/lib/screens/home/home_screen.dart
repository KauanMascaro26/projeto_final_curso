import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../collection_points/collection_points_screen.dart';
import '../identification/identification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? connectionMessage;
  bool isLoading = false;

  Future<void> testApiConnection() async {
    setState(() {
      isLoading = true;
      connectionMessage = null;
    });

    try {
      final message = await ApiService.testConnection();

      setState(() {
        connectionMessage = '✅ $message';
      });
    } catch (e) {
      setState(() {
        connectionMessage = '❌ Não foi possível conectar à API.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Descarte Inteligente'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Descarte Inteligente',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Identifique seus resíduos e encontre o local adequado para o descarte.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const IdentificationScreen(),
                  ),
                );
              },
              child: const Text('Identificar resíduo'),
            ),

            const SizedBox(height: 16),

            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CollectionPointsScreen(),
                  ),
                );
              },
              child: const Text('Pontos de coleta'),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: isLoading ? null : testApiConnection,
              icon: const Icon(Icons.cloud),
              label: Text(
                isLoading
                    ? 'Testando conexão...'
                    : 'Testar conexão com API',
              ),
            ),

            if (connectionMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                connectionMessage!,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}