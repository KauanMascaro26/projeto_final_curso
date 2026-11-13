import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/favorite_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  static const _background = Color(0xFF07131D);
  static const _surface = Color(0xFF0D202B);
  static const _green = Color(0xFF55D6A2);
  static const _text = Color(0xFFF2F8FA);
  static const _muted = Color(0xFFADC1CC);
  late Future<List<Map<String, dynamic>>> _favorites;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _favorites = FavoriteService.getAll();
  }

  Future<void> _remove(String type, int id) async {
    try {
      await FavoriteService.remove(type, id);
      if (!mounted) return;
      setState(_load);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removido dos favoritos.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível remover o favorito.')),
      );
    }
  }

  Future<void> _openInGoogleMaps(Map<String, dynamic> point) async {
    final latitude = (point['latitude'] as num?)?.toDouble();
    final longitude = (point['longitude'] as num?)?.toDouble();
    final hasValidCoordinates = latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        (latitude != 0 || longitude != 0);
    final address = (point['endereco'] ?? '').toString().trim();
    final name = (point['nome'] ?? '').toString().trim();
    final destination = hasValidCoordinates
        ? '$latitude,$longitude'
        : address.isNotEmpty
            ? address
            : name;

    if (destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este ponto não possui localização cadastrada.')),
      );
      return;
    }

    final url = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
    });

    try {
      final opened = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o Google Maps.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao abrir o Google Maps.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Favoritos'),
        backgroundColor: _background,
        foregroundColor: _text,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _favorites,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: _muted, size: 42),
                    const SizedBox(height: 12),
                    const Text(
                      'Não foi possível carregar seus favoritos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _text, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => setState(_load),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }
          final items = (snapshot.data ?? [])
              .where((item) => item['type'] == 'point')
              .toList();
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border, color: _muted, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'Você ainda não salvou favoritos.',
                      style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Salve pontos de coleta para encontrá-los rapidamente aqui.',
                      style: TextStyle(color: _muted, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 9),
            itemBuilder: (context, index) {
              final item = items[index];
              final rawData = item['data'];
              final data = rawData is Map
                  ? Map<String, dynamic>.from(rawData)
                  : <String, dynamic>{};
              final title = (data['nome'] ?? 'Ponto de coleta').toString();
              final subtitle = (data['endereco'] ?? 'Endereço não informado').toString();
              return Container(
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF204653)),
                ),
                child: ListTile(
                  onTap: () => _openInGoogleMaps(data),
                  leading: Icon(
                    Icons.location_on_outlined,
                    color: _green,
                  ),
                  title: Text(title, style: const TextStyle(color: _text, fontWeight: FontWeight.bold)),
                  subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.map_outlined, color: _muted, size: 19),
                      IconButton(
                        tooltip: 'Remover dos favoritos',
                        icon: const Icon(Icons.favorite, color: _green),
                        onPressed: item['id'] is num
                            ? () => _remove(
                                  item['type'].toString(),
                                  (item['id'] as num).toInt(),
                                )
                            : null,
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
