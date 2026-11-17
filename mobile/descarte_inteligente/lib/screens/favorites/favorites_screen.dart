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
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _palette.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _palette.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _palette.cardAccent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.favorite_rounded,
                        color: _palette.primaryForeground,
                        size: 25,
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seus pontos salvos',
                            style: TextStyle(
                              color: _text,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Acesse rapidamente os locais que você marcou.',
                            style: TextStyle(color: _muted, fontSize: 12, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        color: _palette.cardAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${items.length}',
                        style: TextStyle(
                          color: _palette.primaryForeground,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18),
              ...items.map((item) {
                final rawData = item['data'];
                final data = rawData is Map
                    ? Map<String, dynamic>.from(rawData)
                    : <String, dynamic>{};
                final title = (data['nome'] ?? 'Ponto de coleta').toString();
                final subtitle = (data['endereco'] ?? 'Endereço não informado').toString();
                final origin = (data['origem'] ?? 'Público').toString();
                final types = (data['tipos_residuos'] is List)
                    ? List<String>.from(data['tipos_residuos'])
                    : <String>[];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _palette.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.035),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: () => _openInGoogleMaps(data),
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: _palette.cardAccent,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    color: _palette.primaryForeground,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: _text,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        subtitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: _muted,
                                          fontSize: 12,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Remover dos favoritos',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: item['id'] is num
                                      ? () => _remove(
                                            item['type'].toString(),
                                            (item['id'] as num).toInt(),
                                          )
                                      : null,
                                  icon: Icon(
                                    Icons.favorite_rounded,
                                    color: _palette.primaryForeground,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 13),
                            Row(
                              children: [
                                Icon(Icons.account_balance_outlined, size: 15, color: _muted),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    origin,
                                    style: TextStyle(
                                      color: _muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(Icons.open_in_new_rounded, size: 16, color: _palette.primaryForeground),
                                SizedBox(width: 4),
                                Text(
                                  'Ver rota',
                                  style: TextStyle(
                                    color: _palette.primaryForeground,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            if (types.isNotEmpty) ...[
                              SizedBox(height: 12),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: types.take(4).map((type) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _palette.cardAccent,
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Text(
                                      type,
                                      style: TextStyle(
                                        color: _palette.primaryForeground,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
