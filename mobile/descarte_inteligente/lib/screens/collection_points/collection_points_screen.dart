import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';

import '../../core/widgets/app_notification.dart';
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
  AppPalette get _palette => context.appPalette;
  Color get _background => _palette.background;
  Color get _surface => _palette.surface;
  Color get _surfaceRaised => _palette.surfaceRaised;
  Color get _green => _palette.primary;
  static const _cyan = AppColors.cyan;
  Color get _darkGreen => _palette.text;
  Color get _muted => _palette.muted;
  Color get _border => _palette.border;
  static const _purple = Color(0xFFB69CFF);
  static const _orange = Color(0xFFFFB45C);
  static const _blue = Color(0xFF69B7FF);
  static const _yellow = Color(0xFFFFD166);
  static const _teal = Color(0xFF55D6C2);
  static const _grey = Color(0xFFB0BEC5);

  late Future<List<Map<String, dynamic>>> nearbyPoints;

  GoogleMapController? mapController;

  double? userLatitude;
  double? userLongitude;
  bool _hasLocationPermission = false;

  final Set<String> selectedFilters = {};
  String searchText = '';

  @override
  void initState() {
    super.initState();
    nearbyPoints = loadNearbyPoints();
  }

  Future<List<Map<String, dynamic>>> loadNearbyPoints() async {
    double? latitude;
    double? longitude;

    try {
      final position = await LocationService.getCurrentLocation();
      latitude = position.latitude;
      longitude = position.longitude;

      if (mounted) {
        setState(() {
          userLatitude = latitude;
          userLongitude = longitude;
          _hasLocationPermission = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          userLatitude = -22.0175;
          userLongitude = -47.8908;
          _hasLocationPermission = false;
        });
      }

      // A localização é opcional: sem permissão, ainda exibimos os pontos
      // cadastrados, centralizando o mapa em São Carlos.
      final points = await ApiService.getCollectionPoints();
      return points.map((point) => {
        'id': point.id,
        'nome': point.nome,
        'endereco': point.endereco,
        'tipos_residuos': point.tiposResiduos,
        'latitude': point.latitude,
        'longitude': point.longitude,
        'origem': point.origem,
      }).toList();
    }

    return ApiService.getNearbyCollectionPoints(latitude, longitude);
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
          zoom: 17,
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
        AppNotification.show(
          context,
          'Não foi possível abrir o Google Maps.',
          type: AppNotificationType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(
          context,
          'Não foi possível abrir o mapa. Tente novamente.',
          type: AppNotificationType.error,
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
          icon: BitmapDescriptor.defaultMarkerWithHue(150),
          infoWindow: InfoWindow(
            title: point['nome'],
            snippet: point['distancia_km'] is num
              ? '${(point['distancia_km'] as num).toStringAsFixed(2)} km de distância'
              : (point['endereco'] ?? '').toString(),
          ),
          onTap: () {
            focusOnPoint(point);
            _showPointDetails(point);
          },
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

      final matchesFilter = selectedFilters.isEmpty ||
          types.any(
            (type) => selectedFilters.any(
              (selected) => _normalizeWasteType(type) == _normalizeWasteType(selected),
            ),
          );

      final name = (point['nome'] ?? '').toString().toLowerCase();
      final address =
          (point['endereco'] ?? '').toString().toLowerCase();

      final matchesSearch =
          query.isEmpty || name.contains(query) || address.contains(query);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  String _normalizeWasteType(String type) {
    return type.trim().toLowerCase()
        .replaceAll('á', 'a').replaceAll('ã', 'a').replaceAll('â', 'a')
        .replaceAll('à', 'a').replaceAll('é', 'e').replaceAll('ê', 'e')
        .replaceAll('í', 'i').replaceAll('ó', 'o').replaceAll('ô', 'o')
        .replaceAll('õ', 'o').replaceAll('ú', 'u').replaceAll('ç', 'c');
  }

  Color _categoryColor(String type) {
    final value = _normalizeWasteType(type);
    if (value.contains('pilha') || value.contains('bateria')) return _orange;
    if (value.contains('eletron') || value.contains('celular') || value.contains('computador')) return _purple;
    if (value.contains('oleo')) return _yellow;
    if (value.contains('vidro')) return _teal;
    if (value.contains('aluminio') || value.contains('metal') || value.contains('lata')) return _grey;
    if (value.contains('papel') || value.contains('papelao')) return _yellow;
    if (value.contains('plastico') || value.contains('pet')) return _blue;
    return _green;
  }

  IconData _categoryIcon(String type) {
    final value = _normalizeWasteType(type);
    if (value.contains('pilha') || value.contains('bateria')) return Icons.battery_alert_outlined;
    if (value.contains('eletron') || value.contains('celular') || value.contains('computador')) return Icons.devices_outlined;
    if (value.contains('oleo')) return Icons.water_drop_outlined;
    if (value.contains('vidro')) return Icons.wine_bar_outlined;
    if (value.contains('aluminio') || value.contains('metal') || value.contains('lata')) return Icons.inventory_2_outlined;
    if (value.contains('papel') || value.contains('papelao')) return Icons.description_outlined;
    if (value.contains('plastico') || value.contains('pet')) return Icons.recycling;
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
            colorScheme: Theme.of(context).colorScheme.copyWith(
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
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: _darkGreen,
                          ),
                        ),
                      ),
                      _PointFavoriteButton(point: point),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: _palette.primaryForeground,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          displayAddress,
                          style: TextStyle(
                            color: _muted,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.account_balance_outlined, color: _cyan, size: 19),
                      SizedBox(width: 8),
                      Text(
                        _originLabel(collectionPoint.origem),
                        style: TextStyle(color: _muted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  if (distance != null) ...[
                    SizedBox(height: 12),
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
                        style: TextStyle(
                          color: _darkGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 22),
                  Text(
                    'Tipos de resíduos aceitos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
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
                            SizedBox(width: 7),
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
                  SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _surfaceRaised,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
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
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        openRoute(point);
                      },
                      icon: Icon(Icons.navigation_outlined),
                      label: Text('Ver rota no Google Maps'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: _palette.primaryForeground,
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
            return Center(
              child: CircularProgressIndicator(color: _green),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState();
          }

          final allPoints = snapshot.data ?? [];
          final points = filterPoints(allPoints);

          if (allPoints.isEmpty) {
            return Center(
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
              Icon(Icons.search_off_rounded, color: _cyan, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Nenhum ponto corresponde à pesquisa ou ao filtro selecionado.',
                  style: TextStyle(color: _darkGreen, height: 1.4),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedFilters.clear();
                    searchText = '';
                  });
                },
                child: Text('Limpar'),
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
      myLocationEnabled: _hasLocationPermission,
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
    final availableFilters = allPoints
        .expand((point) => List<String>.from(point['tipos_residuos'] ?? const []))
        .map((type) => type.trim())
        .where((type) => type.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final filters = ['Todos', ...availableFilters];

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
                  icon: Icon(Icons.arrow_back, size: 21),
                  color: _darkGreen,
                ),
                Expanded(
                  child: Text(
                    'Pontos de coleta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _darkGreen,
                    ),
                  ),
                ),
                AppThemeToggleButton(color: _darkGreen),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(width: 38, height: 38),
                  padding: EdgeInsets.zero,
                  onPressed: refreshLocation,
                  icon: Icon(Icons.my_location, size: 20),
                  color: _palette.primaryForeground,
                  tooltip: 'Atualizar localização',
                ),
              ],
            ),
            SizedBox(
              height: 42,
              child: TextField(
                style: TextStyle(color: _darkGreen, fontSize: 13),
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar local ou endereço...',
                  hintStyle: TextStyle(color: _muted, fontSize: 13),
                  prefixIcon: Icon(Icons.search, size: 19),
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
            SizedBox(height: 7),
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (_, _) => SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final isAll = filter == 'Todos';
                  final selected = isAll ? selectedFilters.isEmpty : selectedFilters.contains(filter);

                  return ChoiceChip(
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 3),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        if (isAll) {
                          selectedFilters.clear();
                        } else if (selected) {
                          selectedFilters.remove(filter);
                        } else {
                          selectedFilters.add(filter);
                        }
                      });
                    },
                    avatar: Icon(
                      isAll ? Icons.grid_view_rounded : _categoryIcon(filter),
                      size: 14,
                      color: selected ? _palette.primaryForeground : _muted,
                    ),
                    label: Text(filter, style: TextStyle(fontSize: 11)),
                    labelStyle: TextStyle(
                      color: selected ? _palette.primaryForeground : _muted,
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
    final distance = (point['distancia_km'] as num?)?.toDouble();

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
                  child: Icon(
                    Icons.location_on,
                    color: _palette.primaryForeground,
                    size: 22,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        collectionPoint.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _darkGreen,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        displayAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: _muted,
                        ),
                      ),
                      SizedBox(height: 2),
                      if (distance != null)
                        Text(
                          '${distance.toStringAsFixed(2)} km de você',
                          style: TextStyle(
                            color: _green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
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
                child: Icon(
                  Icons.location_off_outlined,
                  size: 38,
                  color: _green,
                ),
              ),
              SizedBox(height: 18),
              Text(
                'Não foi possível obter os pontos de coleta.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _darkGreen,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Verifique sua localização e a conexão com o servidor.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted),
              ),
              SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: refreshLocation,
                icon: Icon(Icons.refresh),
                label: Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
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
  Color get _activeGreen => context.appPalette.primary;
  Color get _outlineGreen => context.appPalette.primary;
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
      AppNotification.show(
        context,
        _isSaved
            ? 'Ponto salvo nos favoritos.'
            : 'Ponto removido dos favoritos.',
        type: _isSaved
            ? AppNotificationType.success
            : AppNotificationType.removed,
        icon: _isSaved ? Icons.favorite_rounded : Icons.heart_broken_rounded,
        bottomOffset: 112,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppNotification.show(
        context,
        'Não foi possível atualizar os favoritos.',
        type: AppNotificationType.error,
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
