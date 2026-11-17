import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';

import '../../core/widgets/app_notification.dart';
import '../../services/favorite_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  AppPalette get _palette => context.appPalette;
  Color get _background => _palette.background;
  Color get _surface => _palette.surface;
  Color get _green => _palette.primary;
  Color get _text => _palette.text;
  Color get _muted => _palette.muted;
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
      AppNotification.show(
        context,
        'Removido dos favoritos.',
        type: AppNotificationType.removed,
      );
    } catch (_) {
      if (!mounted) return;
      AppNotification.show(
        context,
        'Não foi possível remover o favorito.',
        type: AppNotificationType.error,
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
      AppNotification.show(
        context,
        'Este ponto não possui localização cadastrada.',
        type: AppNotificationType.warning,
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
        AppNotification.show(
          context,
          'Não foi possível abrir o Google Maps.',
          type: AppNotificationType.error,
        );
      }
    } catch (_) {
      if (mounted) {
        AppNotification.show(
          context,
          'Erro ao abrir o Google Maps.',
          type: AppNotificationType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: Text('Favoritos'),
        backgroundColor: _background,
        foregroundColor: _text,
        actions: [AppThemeToggleButton()],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _favorites,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: _muted, size: 42),
                    SizedBox(height: 12),
                    Text(
                      'Não foi possível carregar seus favoritos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _text, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => setState(_load),
                      icon: Icon(Icons.refresh),
                      label: Text('Tentar novamente'),
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
            return Center(
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
            separatorBuilder: (_, _) => SizedBox(height: 9),
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
                  border: Border.all(color: _palette.border),
                ),
                child: ListTile(
                  onTap: () => _openInGoogleMaps(data),
                  leading: Icon(
                    Icons.location_on_outlined,
                    color: _palette.primaryForeground,
                  ),
                  title: Text(title, style: TextStyle(color: _text, fontWeight: FontWeight.bold)),
                  subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: _muted)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map_outlined, color: _muted, size: 19),
                      IconButton(
                        tooltip: 'Remover dos favoritos',
                        icon: Icon(Icons.favorite, color: _palette.primaryForeground),
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
