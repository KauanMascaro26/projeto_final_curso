import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../services/favorite_service.dart';

class IdentificationScreen extends StatefulWidget {
  const IdentificationScreen({super.key});

  @override
  State<IdentificationScreen> createState() => _IdentificationScreenState();
}

class _IdentificationScreenState extends State<IdentificationScreen> {
  static const _background = Color(0xFF07131D);
  static const _surface = Color(0xFF0D202B);
  static const _surfaceRaised = Color(0xFF122B38);
  static const _green = Color(0xFF55D6A2);
  static const _cyan = Color(0xFF53D9F5);
  static const _darkGreen = Color(0xFFF2F8FA);
  static const _muted = Color(0xFFADC1CC);
  static const _border = Color(0xFF204653);

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _wasteTypes = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _loadWasteTypes();
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

  Future<void> _toggleWasteFavorite(Map<String, dynamic> waste) async {
    final id = (waste['id'] as num).toInt();
    final wasSaved = await FavoriteService.contains('waste', id);
    await FavoriteService.toggle(type: 'waste', data: waste);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(wasSaved ? 'Resíduo removido dos favoritos.' : 'Resíduo salvo nos favoritos.'),
      ),
    );
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
                    style: const TextStyle(
                      color: _darkGreen,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _toggleWasteFavorite(waste),
                      icon: const Icon(Icons.favorite_border, size: 18),
                      label: const Text('Salvar nos favoritos'),
                      style: TextButton.styleFrom(foregroundColor: _green),
                    ),
                  ),
                  Chip(
                    backgroundColor: _surfaceRaised,
                    label: Text(
                      waste['categoria']?.toString() ?? 'Sem categoria',
                      style: const TextStyle(color: _cyan, fontWeight: FontWeight.w600),
                    ),
                    avatar: const Icon(Icons.category_outlined, size: 18, color: _cyan),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(description, style: const TextStyle(color: _muted, fontSize: 15, height: 1.4)),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'Como descartar',
                    style: TextStyle(color: _darkGreen, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    waste['orientacao_descarte']?.toString() ??
                        'Não há orientação cadastrada.',
                    style: const TextStyle(color: _muted, fontSize: 15, height: 1.4),
                  ),
                  if (preparation.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Text(
                      'Preparação do material',
                      style: TextStyle(color: _darkGreen, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(preparation, style: const TextStyle(color: _muted, fontSize: 15, height: 1.4)),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        waste['reciclavel'] == true
                            ? Icons.recycling
                            : Icons.info_outline,
                        color: _green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          waste['reciclavel'] == true
                              ? 'Material reciclável'
                              : 'Pode exigir um ponto de recebimento específico',
                          style: const TextStyle(color: _darkGreen, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showCompatiblePoints(waste);
                      },
                      icon: const Icon(Icons.location_on_outlined),
                      label: const Text('Ver pontos de coleta compatíveis'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: _background,
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


  Future<void> _showCompatiblePoints(Map<String, dynamic> waste) async {
    final wasteId = (waste['id'] as num).toInt();
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
                    style: const TextStyle(
                      color: _darkGreen,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Locais associados a este resíduo no cadastro do aplicativo.',
                    style: TextStyle(color: _muted, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: ApiService.getCollectionPointsForWaste(wasteId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text(
                              'Não foi possível carregar os pontos. Tente novamente.',
                              style: TextStyle(color: _muted),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        final points = snapshot.data ?? [];
                        if (points.isEmpty) {
                          return const Center(
                            child: Text(
                              'Ainda não há pontos associados a este resíduo.',
                              style: TextStyle(color: _muted),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: points.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 9),
                          itemBuilder: (context, index) {
                            final point = points[index];
                            final name = point['nome']?.toString() ?? 'Ponto de coleta';
                            final address = point['endereco']?.toString() ?? 'Endereço não informado';
                            final latitude = (point['latitude'] as num?)?.toDouble();
                            final longitude = (point['longitude'] as num?)?.toDouble();
                            return Container(
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: _surfaceRaised,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: _border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, color: _green),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: const TextStyle(color: _darkGreen, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(address, style: const TextStyle(color: _muted, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  if (latitude != null && longitude != null)
                                    IconButton(
                                      tooltip: 'Abrir rota',
                                      icon: const Icon(Icons.directions, color: _cyan),
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
                  const SizedBox(height: 10),
                  const Text(
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
        title: const Text('Identificar resíduo'),
        backgroundColor: _background,
        foregroundColor: _darkGreen,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            decoration: const BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: const Text(
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
                    style: const TextStyle(color: _darkGreen),
                    decoration: InputDecoration(
                      hintText: 'Ex.: garrafa PET, pilha, papelão',
                      prefixIcon: const Icon(Icons.search, color: _cyan),
                      prefixIconColor: _cyan,
                      hintStyle: const TextStyle(color: _muted),
                      filled: true,
                      fillColor: _surfaceRaised,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _border),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _loadWasteTypes(query: _searchController.text),
                  style: IconButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  icon: const Icon(Icons.search),
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
                  icon: const Icon(Icons.close),
                  label: const Text('Limpar pesquisa'),
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_off_outlined, size: 48, color: _muted),
                              const SizedBox(height: 12),
                              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: _muted)),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () => _loadWasteTypes(
                                  query: _searchController.text,
                                ),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _wasteTypes.isEmpty
                        ? const Center(
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
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final waste = _wasteTypes[index];
                              return Card(
                                color: _surface,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: const BorderSide(color: _border),
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
                                    child: const Icon(Icons.recycling, color: _green),
                                  ),
                                  title: Text(
                                    waste['nome']?.toString() ?? 'Resíduo',
                                    style: const TextStyle(color: _darkGreen, fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Text(
                                      '${waste['categoria'] ?? 'Sem categoria'}\n'
                                      '${waste['descricao'] ?? ''}',
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: _muted),
                                    ),
                                  ),
                                  isThreeLine: true,
                                  trailing: const Icon(Icons.chevron_right, color: _muted),
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
