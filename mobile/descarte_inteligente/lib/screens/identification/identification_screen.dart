import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class IdentificationScreen extends StatefulWidget {
  const IdentificationScreen({super.key});

  @override
  State<IdentificationScreen> createState() => _IdentificationScreenState();
}

class _IdentificationScreenState extends State<IdentificationScreen> {
  static const _green = Color(0xFF249B57);
  static const _darkGreen = Color(0xFF173D2B);

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

  void _showWasteDetails(Map<String, dynamic> waste) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
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
                  Chip(
                    label: Text(waste['categoria']?.toString() ?? 'Sem categoria'),
                    avatar: const Icon(Icons.category_outlined, size: 18),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(description, style: const TextStyle(fontSize: 15)),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'Como descartar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    waste['orientacao_descarte']?.toString() ??
                        'Não há orientação cadastrada.',
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                  if (preparation.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Text(
                      'Preparação do material',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(preparation, style: const TextStyle(fontSize: 15, height: 1.4)),
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
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
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
      appBar: AppBar(
        title: const Text('Identificar resíduo'),
        backgroundColor: _darkGreen,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            decoration: const BoxDecoration(
              color: _darkGreen,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: const Text(
              'O que você precisa descartar?\nPesquise um material para ver as orientações corretas.',
              style: TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
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
                    decoration: InputDecoration(
                      hintText: 'Ex.: garrafa PET, pilha, papelão',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
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
                              const Icon(Icons.cloud_off_outlined, size: 48),
                              const SizedBox(height: 12),
                              Text(_errorMessage!, textAlign: TextAlign.center),
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
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _wasteTypes.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final waste = _wasteTypes[index];
                              return Card(
                                color: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: const BorderSide(color: Color(0xFFE5ECE6)),
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
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Text(
                                      '${waste['categoria'] ?? 'Sem categoria'}\n'
                                      '${waste['descricao'] ?? ''}',
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  isThreeLine: true,
                                  trailing: const Icon(Icons.chevron_right),
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
