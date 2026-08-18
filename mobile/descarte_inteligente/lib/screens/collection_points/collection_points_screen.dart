import 'package:flutter/material.dart';

import '../../models/collection_point.dart';
import '../../services/api_service.dart';

class CollectionPointsScreen extends StatefulWidget {
  const CollectionPointsScreen({super.key});

  @override
  State<CollectionPointsScreen> createState() =>
      _CollectionPointsScreenState();
}

class _CollectionPointsScreenState
    extends State<CollectionPointsScreen> {
  late Future<List<CollectionPoint>> collectionPoints;

  @override
  void initState() {
    super.initState();
    collectionPoints = ApiService.getCollectionPoints();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pontos de coleta'),
      ),
      body: FutureBuilder<List<CollectionPoint>>(
        future: collectionPoints,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Não foi possível carregar os pontos de coleta.',
              ),
            );
          }

          final points = snapshot.data ?? [];

          if (points.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum ponto de coleta encontrado.',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: points.length,
            itemBuilder: (context, index) {
              final point = points[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        point.nome,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(point.endereco),
                      const SizedBox(height: 8),
                      Text(
                        'Aceita: ${point.tiposResiduos.join(', ')}',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}