import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/collection_point.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';

class CollectionPointsScreen extends StatefulWidget {
  const CollectionPointsScreen({super.key});

  @override
  State<CollectionPointsScreen> createState() =>
      _CollectionPointsScreenState();
}

class _CollectionPointsScreenState extends State<CollectionPointsScreen> {
  static const _green = Color(0xFF249B57);
  static const _darkGreen = Color(0xFF173D2B);
  static const _blue = Color(0xFF2F80ED);
  static const _purple = Color(0xFF7657C8);
  static const _orange = Color(0xFFF2A51A);
  static const _red = Color(0xFFE34D4D);

  late Future<List<Map<String, dynamic>>> nearbyPoints;

  GoogleMapController? mapController;

  double? userLatitude;
  double? userLongitude;

  String selectedFilter = 'Todos';
  String searchText = '';

  @override
  void initState() {
    super.initState();
    nearbyPoints = loadNearbyPoints();
  }

  Future<List<Map<String, dynamic>>> loadNearbyPoints() async {
    final position = await LocationService.getCurrentLocation();

    if (mounted) {
      setState(() {
        userLatitude = position.latitude;
        userLongitude = position.longitude;
      });
    }

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

  void focusOnPoint(Map<String, dynamic> point) {
    final latitude = (point['latitude'] as num).toDouble();
    final longitude = (point['longitude'] as num).toDouble();

    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(latitude, longitude),
          zoom: 16,
        ),
      ),
    );
  }

  Future<void> openRoute(Map<String, dynamic> point) async {
    final latitude = (point['latitude'] as num).toDouble();
    final longitude = (point['longitude'] as num).toDouble();

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$latitude,$longitude',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o Google Maps.'),
        ),
      );
    }
  }

  Set<Marker> buildMarkers(List<Map<String, dynamic>> points) {
    final markers = <Marker>{};

    if (userLatitude != null && userLongitude != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: LatLng(userLatitude!, userLongitude!),
          infoWindow: const InfoWindow(title: 'Você está aqui'),
        ),
      );
    }

    for (final point in points) {
      markers.add(
        Marker(
          markerId: MarkerId('point_${point['id']}'),
          position: LatLng(
            (point['latitude'] as num).toDouble(),
            (point['longitude'] as num).toDouble(),
          ),
          infoWindow: InfoWindow(
            title: point['nome'],
            snippet: '${point['distancia_km']} km de distância',
          ),
          onTap: () => _showPointDetails(point),
        ),
      );
    }

    return markers;
  }

  List<Map<String, dynamic>> filterPoints(
    List<Map<String, dynamic>> points,
  ) {
    final query = searchText.trim().toLowerCase();

    return points.where((point) {
      final types = List<String>.from(point['tipos_residuos'] ?? const []);

      final matchesFilter = selectedFilter == 'Todos' ||
          types.any(
            (type) => _matchesCategory(type, selectedFilter),
          );

      final name = (point['nome'] ?? '').toString().toLowerCase();
      final address =
          (point['endereco'] ?? '').toString().toLowerCase();

      final matchesSearch =
          query.isEmpty || name.contains(query) || address.contains(query);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  bool _matchesCategory(String type, String category) {
    final value = type.toLowerCase();

    switch (category) {
      case 'Recicláveis':
        return value.contains('recicl');
      case 'Eletrônicos':
        return value.contains('eletr');
      case 'Óleo':
        return value.contains('óleo') || value.contains('oleo');
      case 'Pilhas':
        return value.contains('pilha') || value.contains('bateria');
      default:
        return true;
    }
  }

  Color _categoryColor(String type) {
    final value = type.toLowerCase();

    if (value.contains('eletr')) return _purple;
    if (value.contains('óleo') || value.contains('oleo')) return _orange;
    if (value.contains('pilha') || value.contains('bateria')) return _red;
    return _green;
  }

  IconData _categoryIcon(String type) {
    final value = type.toLowerCase();

    if (value.contains('eletr')) return Icons.computer_outlined;
    if (value.contains('óleo') || value.contains('oleo')) {
      return Icons.water_drop_outlined;
    }
    if (value.contains('pilha') || value.contains('bateria')) {
      return Icons.battery_alert_outlined;
    }
    return Icons.recycling;
  }

  void _showPointDetails(Map<String, dynamic> point) {
    final collectionPoint = CollectionPoint.fromJson(point);
    final distance = (point['distancia_km'] as num?)?.toDouble();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          collectionPoint.nome,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: _darkGreen,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: _green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          collectionPoint.endereco,
                          style: const TextStyle(
                            color: Colors.black54,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (distance != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF7EF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${distance.toStringAsFixed(2)} km de você',
                        style: const TextStyle(
                          color: _darkGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  const Text(
                    'Tipos de resíduos aceitos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: collectionPoint.tiposResiduos.map((type) {
                      final color = _categoryColor(type);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _categoryIcon(type),
                              size: 20,
                              color: color,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              type,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        openRoute(point);
                      },
                      icon: const Icon(Icons.navigation_outlined),
                      label: const Text('Ver rota no Google Maps'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: nearbyPoints,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _green),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState();
          }

          final allPoints = snapshot.data ?? [];
          final points = filterPoints(allPoints);

          if (allPoints.isEmpty) {
            return const Center(
              child: Text('Nenhum ponto de coleta encontrado.'),
            );
          }

          return SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _buildMap(allPoints),
                ),
                _buildTopPanel(),
                _buildBottomCard(points.isEmpty ? allPoints.first : points.first),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMap(List<Map<String, dynamic>> allPoints) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(
          userLatitude ?? -22.0175,
          userLongitude ?? -47.8908,
        ),
        zoom: 13.5,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      markers: buildMarkers(allPoints),
      onMapCreated: (controller) {
        mapController = controller;
      },
    );
  }

  Widget _buildTopPanel() {
    final filters = [
      ('Todos', Icons.grid_view_rounded),
      ('Recicláveis', Icons.recycling),
      ('Eletrônicos', Icons.computer_outlined),
      ('Óleo', Icons.water_drop_outlined),
    ];

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  color: _darkGreen,
                ),
                const SizedBox(width: 2),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pontos de coleta',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _darkGreen,
                        ),
                      ),
                      Text(
                        'Encontre os locais mais próximos',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: refreshLocation,
                  icon: const Icon(Icons.my_location),
                  color: _green,
                  tooltip: 'Atualizar localização',
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar por bairro ou local...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF4F6F4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final selected = selectedFilter == filter.$1;

                  return ChoiceChip(
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        selectedFilter = filter.$1;
                      });
                    },
                    avatar: Icon(
                      filter.$2,
                      size: 17,
                      color: selected ? Colors.white : _darkGreen,
                    ),
                    label: Text(filter.$1),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : _darkGreen,
                      fontWeight: FontWeight.w600,
                    ),
                    selectedColor: _green,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: selected
                          ? _green
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCard(Map<String, dynamic> point) {
    final collectionPoint = CollectionPoint.fromJson(point);
    final distance = (point['distancia_km'] as num).toDouble();

    return Positioned(
      left: 16,
      right: 16,
      bottom: 18,
      child: Material(
        color: Colors.white,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () => _showPointDetails(point),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: _green,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        collectionPoint.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        collectionPoint.endereco,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${distance.toStringAsFixed(2)} km',
                        style: const TextStyle(
                          color: _green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 17,
                  color: _green,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_off_outlined,
                  size: 38,
                  color: _green,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Não foi possível obter os pontos de coleta.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Verifique sua localização e a conexão com o servidor.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: refreshLocation,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
