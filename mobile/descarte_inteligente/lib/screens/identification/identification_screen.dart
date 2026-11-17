import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';

import '../../services/api_service.dart';
import '../../services/location_service.dart';

class IdentificationScreen extends StatefulWidget {
  final String? initialQuery;

  const IdentificationScreen({super.key, this.initialQuery});

  @override
  State<IdentificationScreen> createState() => _IdentificationScreenState();
}

class _IdentificationScreenState extends State<IdentificationScreen> {
  AppPalette get _palette => context.appPalette;
  Color get _background => _palette.background;
  Color get _surface => _palette.surface;
  Color get _surfaceRaised => _palette.surfaceRaised;
  Color get _green => _palette.primary;
  static const _cyan = AppColors.cyan;
  Color get _darkGreen => _palette.text;
  Color get _muted => _palette.muted;
  Color get _border => _palette.border;

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _wasteTypes = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    final initialQuery = widget.initialQuery?.trim() ?? '';
    if (initialQuery.isNotEmpty) {
      _searchController.text = initialQuery;
    }
    _loadWasteTypes(query: initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWasteTypes({String query = ''}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentQuery = query.trim();
    });

    try {
      final results = _currentQuery.isEmpty
          ? await ApiService.getWasteTypes()
          : await ApiService.searchWasteTypes(_currentQuery);

      if (!mounted) return;

      setState(() {
        _wasteTypes = results;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Não foi possível carregar os resíduos. Verifique sua conexão com a API.';
      });
    }
  }

  void _showWasteDetails(Map<String, dynamic> waste) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _surface,
      builder: (context) {
        final preparation = (waste['preparacao'] ?? '').toString();
        final description = (waste['descricao'] ?? '').toString();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    waste['nome']?.toString() ?? 'Resíduo',
                    style: TextStyle(
                      color: _darkGreen,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Chip(
                    backgroundColor: _surfaceRaised,
                    label: Text(
                      waste['categoria']?.toString() ?? 'Sem categoria',
                      style: TextStyle(color: _cyan, fontWeight: FontWeight.w600),
                    ),
                    avatar: Icon(Icons.category_outlined, size: 18, color: _cyan),
                  ),
                  if (description.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Text(description, style: TextStyle(color: _muted, fontSize: 15, height: 1.4)),
                  ],
                  SizedBox(height: 20),
                  Text(
                    'Como descartar',
                    style: TextStyle(color: _darkGreen, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    waste['orientacao_descarte']?.toString() ??
                        'Não há orientação cadastrada.',
                    style: TextStyle(color: _muted, fontSize: 15, height: 1.4),
                  ),
                  if (preparation.isNotEmpty) ...[
                    SizedBox(height: 18),
                    Text(
                      'Preparação do material',
                      style: TextStyle(color: _darkGreen, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(preparation, style: TextStyle(color: _muted, fontSize: 15, height: 1.4)),
                  ],
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        waste['reciclavel'] == true
                            ? Icons.recycling
                            : Icons.info_outline,
                        color: _palette.primaryForeground,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          waste['reciclavel'] == true
                              ? 'Material reciclável'
                              : 'Pode exigir um ponto de recebimento específico',
                          style: TextStyle(color: _darkGreen, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showCompatiblePoints(waste);
                      },
                      icon: Icon(Icons.location_on_outlined),
                      label: Text('Ver pontos de coleta compatíveis'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: _palette.primaryForeground,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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


  Future<List<Map<String, dynamic>>> _loadCompatiblePoints(int wasteId) async {
    double? latitude;
    double? longitude;

    // A localização é opcional. Se não estiver disponível ou for negada,
    // a API retorna os pontos em ordem alfabética.
    try {
      final position = await LocationService.getCurrentLocation();
      latitude = position.latitude;
      longitude = position.longitude;
    } catch (_) {
      // Mantém a consulta disponível mesmo sem permissão ou sinal de GPS.
    }

    return ApiService.getCollectionPointsForWaste(
      wasteId,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<void> _showCompatiblePoints(Map<String, dynamic> waste) async {
    final wasteId = (waste['id'] as num).toInt();
    final pointsFuture = _loadCompatiblePoints(wasteId);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SizedBox(
              height: MediaQuery.of(sheetContext).size.height * 0.62,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pontos para ${waste['nome']}',
                    style: TextStyle(
                      color: _darkGreen,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Com sua localização autorizada, os pontos aparecem do mais próximo ao mais distante. Sem ela, são listados em ordem alfabética.',
                    style: TextStyle(color: _muted, height: 1.4),
                  ),
                  SizedBox(height: 14),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: pointsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Não foi possível carregar os pontos. Tente novamente.',
                              style: TextStyle(color: _muted),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        final points = snapshot.data ?? [];
                        if (points.isEmpty) {
                          return Center(
                            child: Text(
                              'Ainda não há pontos associados a este resíduo.',
                              style: TextStyle(color: _muted),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: points.length,
                          separatorBuilder: (_, _) => SizedBox(height: 9),
                          itemBuilder: (context, index) {
                            final point = points[index];
                            final name = point['nome']?.toString() ?? 'Ponto de coleta';
                            final address = point['endereco']?.toString() ?? 'Endereço não informado';
                            final latitude = (point['latitude'] as num?)?.toDouble();
                            final longitude = (point['longitude'] as num?)?.toDouble();
                            final distance = (point['distancia_km'] as num?)?.toDouble();
                            return Container(
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: _surfaceRaised,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: _border),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.location_on_outlined, color: _green),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: TextStyle(color: _darkGreen, fontWeight: FontWeight.bold)),
                                        SizedBox(height: 4),
                                        Text(address, style: TextStyle(color: _muted, fontSize: 12)),
                                        if (distance != null) ...[
                                          SizedBox(height: 5),
                                          Text(
                                            '${distance.toStringAsFixed(2)} km em linha reta',
                                            style: TextStyle(
                                              color: _green,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (latitude != null && longitude != null)
                                    IconButton(
                                      tooltip: 'Abrir rota',
                                      icon: Icon(Icons.directions, color: _cyan),
                                      onPressed: () async {
                                        final uri = Uri.https('www.google.com', '/maps/dir/', {
                                          'api': '1',
                                          'destination': '$latitude,$longitude',
                                        });
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      },
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Confirme diretamente com o estabelecimento se ele recebe o material antes de se deslocar.',
                    style: TextStyle(color: _muted, fontSize: 12, height: 1.4),
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
      backgroundColor: _background,
      appBar: AppBar(
        title: Text('Identificar resíduo'),
        backgroundColor: _background,
        foregroundColor: _darkGreen,
        actions: [AppThemeToggleButton()],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Text(
              'O que você precisa descartar?\nPesquise um material para ver as orientações corretas.',
              style: TextStyle(color: _darkGreen, fontSize: 16, height: 1.4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) => _loadWasteTypes(query: value),
                    style: TextStyle(color: _darkGreen),
                    decoration: InputDecoration(
                      hintText: 'Ex.: garrafa PET, pilha, papelão',
                      prefixIcon: Icon(Icons.search, color: _cyan),
                      prefixIconColor: _cyan,
                      hintStyle: TextStyle(color: _muted),
                      filled: true,
                      fillColor: _surfaceRaised,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: _border),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _loadWasteTypes(query: _searchController.text),
                  style: IconButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: _palette.primaryForeground,
                    padding: const EdgeInsets.all(16),
                  ),
                  icon: Icon(Icons.search),
                  tooltip: 'Pesquisar',
                ),
              ],
            ),
          ),
          if (_currentQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    _loadWasteTypes();
                  },
                  style: TextButton.styleFrom(foregroundColor: _cyan),
                  icon: Icon(Icons.close),
                  label: Text('Limpar pesquisa'),
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_off_outlined, size: 48, color: _muted),
                              SizedBox(height: 12),
                              Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: _muted)),
                              SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () => _loadWasteTypes(
                                  query: _searchController.text,
                                ),
                                icon: Icon(Icons.refresh),
                                label: Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _wasteTypes.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Nenhum resíduo encontrado. Tente outra palavra.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: _muted),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _wasteTypes.length,
                            separatorBuilder: (_, _) => SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final waste = _wasteTypes[index];
                              return Card(
                                color: _surface,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: BorderSide(color: _border),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: _green.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(Icons.recycling, color: _green),
                                  ),
                                  title: Text(
                                    waste['nome']?.toString() ?? 'Resíduo',
                                    style: TextStyle(color: _darkGreen, fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Text(
                                      '${waste['categoria'] ?? 'Sem categoria'}\n'
                                      '${waste['descricao'] ?? ''}',
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: _muted),
                                    ),
                                  ),
                                  isThreeLine: true,
                                  trailing: Icon(Icons.chevron_right, color: _muted),
                                  onTap: () => _showWasteDetails(waste),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
