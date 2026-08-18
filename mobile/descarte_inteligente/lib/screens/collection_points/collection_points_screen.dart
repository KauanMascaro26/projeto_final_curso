import 'package:flutter/material.dart';

import '../../models/collection_point.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';

class CollectionPointsScreen extends StatefulWidget {
  const CollectionPointsScreen({super.key});

  @override
  State<CollectionPointsScreen> createState() =>
      _CollectionPointsScreenState();
}

class _CollectionPointsScreenState
    extends State<CollectionPointsScreen> {
  late Future<List<Map<String, dynamic>>> nearbyPoints;

  @override
  void initState() {
    super.initState();
    nearbyPoints = loadNearbyPoints();
  }

  Future<List<Map<String, dynamic>>> loadNearbyPoints() async {
    final position = await LocationService.getCurrentLocation();

    return ApiService.getNearbyCollectionPoints(
      position.latitude,
      position.longitude,
    );
  }

  Future<void> refreshLocation() async {
    setState(() {
      nearbyPoints = loadNearbyPoints();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pontos de coleta'),
        actions: [
          IconButton(
            onPressed: refreshLocation,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: nearbyPoints,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_off,
                      size: 50,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Não foi possível obter os pontos de coleta.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: refreshLocation,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
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

              final collectionPoint = CollectionPoint.fromJson(point);

              final distance =
                  (point['distancia_km'] as num).toDouble();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              collectionPoint.nome,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        collectionPoint.endereco,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Distância: ${distance.toStringAsFixed(2)} km',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Aceita: ${collectionPoint.tiposResiduos.join(', ')}',
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