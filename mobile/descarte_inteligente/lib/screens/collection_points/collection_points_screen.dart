import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/collection_point.dart';
import '../../services/api_service.dart';
import '../../services/favorite_service.dart';
import '../../services/location_service.dart';

class CollectionPointsScreen extends StatefulWidget {
  const CollectionPointsScreen({super.key});

  @override
  State<CollectionPointsScreen> createState() =>
      _CollectionPointsScreenState();
}

class _CollectionPointsScreenState extends State<CollectionPointsScreen> {
  static const _background = Color(0xFF07131D);
  static const _surface = Color(0xFF0D202B);
  static const _surfaceRaised = Color(0xFF122B38);
  static const _green = Color(0xFF55D6A2);
  static const _cyan = Color(0xFF53D9F5);
  static const _darkGreen = Color(0xFFF2F8FA);
  static const _muted = Color(0xFFADC1CC);
  static const _border = Color(0xFF204653);
  static const _purple = _cyan;
  static const _orange = _cyan;
  static const _red = _green;

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

    final url = Uri.https(
      'www.google.com',
      '/maps/dir/',
      {
        'api': '1',
        'destination': '$latitude,$longitude',
      },
    );

    try {
      final opened = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o Google Maps.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir o mapa: $e'),
          ),
        );
      }
    }
  }

  Set<Marker> buildMarkers(List<Map<String, dynamic>> points) {
    final markers = <Marker>{};

    for (final point in points) {
      markers.add(
        Marker(
          markerId: MarkerId('point_${point['id']}'),
          position: LatLng(
            (point['latitude'] as num).toDouble(),
            (point['longitude'] as num).toDouble(),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            ['empresa', 'privado', 'instituicao'].contains(
              point['origem']?.toString().toLowerCase(),
            )
                ? BitmapDescriptor.hueAzure
                : BitmapDescriptor.hueGreen,
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
    final value = type
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u');

    switch (category) {
      case 'Recicláveis':
        return [
          'recicl', 'garrafa', 'pet', 'papel', 'papelao',
          'vidro', 'lata', 'aluminio', 'metal', 'plastico',
        ].any(value.contains);
      case 'Eletrônicos':
        return [
          'eletron', 'celular', 'computador', 'notebook',
          'computador', ' tv', 'televisao',
        ].any(value.contains);
      case 'Óleo':
        return value.contains('oleo');
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

  String _originLabel(String origin) {
    switch (origin.toLowerCase()) {
      case 'publico':
      case 'público':
      case 'prefeitura':
        return 'Ponto público';
      case 'empresa':
      case 'privado':
        return 'Empresa ou estabelecimento privado';
      case 'instituicao':
      case 'instituição':
        return 'Instituição';
      default:
        return 'Origem: $origin';
    }
  }

  void _showPointDetails(Map<String, dynamic> point) {
    final collectionPoint = CollectionPoint.fromJson(point);
    final displayAddress = collectionPoint.endereco.replaceAll('São', 'Sao').replaceAll('são', 'sao');
    final distance = (point['distancia_km'] as num?)?.toDouble();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _surface,
      builder: (context) {
        return Theme(
          data: Theme.of(context).copyWith(
            brightness: Brightness.dark,
            colorScheme: const ColorScheme.dark(
              primary: _green,
              secondary: _cyan,
              surface: _surface,
              onSurface: _darkGreen,
            ),
          ),
          child: SafeArea(
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
                      _PointFavoriteButton(point: point),
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
                          displayAddress,
                          style: const TextStyle(
                            color: _muted,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.account_balance_outlined, color: _cyan, size: 19),
                      const SizedBox(width: 8),
                      Text(
                        _originLabel(collectionPoint.origem),
                        style: const TextStyle(color: _muted, fontWeight: FontWeight.w600),
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
                        color: _green.withValues(alpha: 0.12),
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
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _surfaceRaised,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: _border),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: _cyan, size: 18),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Os materiais exibidos correspondem ao cadastro do aplicativo. Confirme com o local se o recebimento está disponível antes de ir até lá.',
                            style: TextStyle(color: _muted, fontSize: 12, height: 1.4),
                          ),
                        ),
                      ],
                    ),
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
                        foregroundColor: _background,
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
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
              child: Text(
                'Nenhum ponto de coleta encontrado.',
                style: TextStyle(color: _darkGreen),
              ),
            );
          }

          return SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _buildMap(points),
                ),
                _buildTopPanel(allPoints),
                if (points.isNotEmpty)
                  _buildBottomCard(points.first)
                else
                  _buildNoFilteredPointsCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoFilteredPointsCard() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 42,
      child: Material(
        color: _surface,
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(Icons.search_off_rounded, color: _cyan, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Nenhum ponto corresponde à pesquisa ou ao filtro selecionado.',
                  style: TextStyle(color: _darkGreen, height: 1.4),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedFilter = 'Todos';
                    searchText = '';
                  });
                },
                child: const Text('Limpar'),
              ),
            ],
          ),
        ),
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

  Widget _buildTopPanel(List<Map<String, dynamic>> allPoints) {
    const categories = [
      ('Recicláveis', Icons.recycling),
      ('Eletrônicos', Icons.computer_outlined),
      ('Pilhas', Icons.battery_alert_outlined),
      ('Óleo', Icons.water_drop_outlined),
    ];

    final availableFilters = categories.where((category) {
      return allPoints.any((point) {
        final types = List<String>.from(point['tipos_residuos'] ?? const []);
        return types.any((type) => _matchesCategory(type, category.$1));
      });
    }).toList();

    final filters = [
      ('Todos', Icons.grid_view_rounded),
      ...availableFilters,
    ];

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 9),
        decoration: BoxDecoration(
          color: _surface.withValues(alpha: 0.97),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(width: 38, height: 38),
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 21),
                  color: _darkGreen,
                ),
                const Expanded(
                  child: Text(
                    'Pontos de coleta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _darkGreen,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(width: 38, height: 38),
                  padding: EdgeInsets.zero,
                  onPressed: refreshLocation,
                  icon: const Icon(Icons.my_location, size: 20),
                  color: _green,
                  tooltip: 'Atualizar localização',
                ),
              ],
            ),
            SizedBox(
              height: 42,
              child: TextField(
                style: const TextStyle(color: _darkGreen, fontSize: 13),
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar local ou endereço...',
                  hintStyle: const TextStyle(color: _muted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 19),
                  prefixIconColor: _cyan,
                  filled: true,
                  fillColor: _surfaceRaised,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final selected = selectedFilter == filter.$1;

                  return ChoiceChip(
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 3),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        selectedFilter = filter.$1;
                      });
                    },
                    avatar: Icon(
                      filter.$2,
                      size: 14,
                      color: selected ? _background : _muted,
                    ),
                    label: Text(filter.$1, style: const TextStyle(fontSize: 11)),
                    labelStyle: TextStyle(
                      color: selected ? _background : _muted,
                      fontWeight: FontWeight.w600,
                    ),
                    selectedColor: _green,
                    backgroundColor: _surfaceRaised,
                    side: BorderSide(color: selected ? _green : _border),
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
    final displayAddress = collectionPoint.endereco
        .replaceAll('São', 'Sao')
        .replaceAll('são', 'sao');
    final distance = (point['distancia_km'] as num).toDouble();

    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: Material(
        color: _surface,
        elevation: 7,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: () => _showPointDetails(point),
          borderRadius: BorderRadius.circular(17),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: _green,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        collectionPoint.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _darkGreen,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${distance.toStringAsFixed(2)} km de você',
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
                  size: 15,
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
      backgroundColor: _background,
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
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _darkGreen,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Verifique sua localização e a conexão com o servidor.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted),
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


class _MapLegendItem extends StatelessWidget {
  static const _muted = Color(0xFFADC1CC);

  const _MapLegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
      ],
    );
  }
}


class _PointFavoriteButton extends StatefulWidget {
  const _PointFavoriteButton({required this.point});

  final Map<String, dynamic> point;

  @override
  State<_PointFavoriteButton> createState() => _PointFavoriteButtonState();
}

class _PointFavoriteButtonState extends State<_PointFavoriteButton> {
  static const _activeGreen = Color(0xFF16845B);
  static const _outlineGreen = Color(0xFF55D6A2);
  late Future<bool> _savedFuture;
  bool _isSaved = false;
  bool _isLoading = false;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _savedFuture = _loadSaved();
  }

  Future<bool> _loadSaved() async {
    final id = (widget.point['id'] as num).toInt();
    final saved = await FavoriteService.contains('point', id);
    if (mounted) {
      setState(() {
        _isSaved = saved;
        _hasLoaded = true;
      });
    }
    return saved;
  }

  Future<void> _toggle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await FavoriteService.toggle(type: 'point', data: widget.point);
      if (!mounted) return;
      setState(() {
        _isSaved = !_isSaved;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isSaved
                ? 'Ponto salvo nos favoritos.'
                : 'Ponto removido dos favoritos.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível atualizar os favoritos.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _savedFuture,
      builder: (context, _) {
        return IconButton(
          tooltip: _isSaved ? 'Remover dos favoritos' : 'Salvar nos favoritos',
          onPressed: _hasLoaded && !_isLoading ? _toggle : null,
          icon: AnimatedScale(
            scale: _isSaved ? 1.18 : 1.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                _isSaved ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(_isSaved),
                color: _isSaved ? _activeGreen : _outlineGreen,
              ),
            ),
          ),
        );
      },
    );
  }
}
