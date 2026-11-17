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
        title: const Text('Favoritos'),
        backgroundColor: _background,
        foregroundColor: _text,
        elevation: 0,
        actions: [AppThemeToggleButton()],
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
                    Icon(Icons.error_outline_rounded, color: _muted, size: 42),
                    const SizedBox(height: 12),
                    Text(
                      'Não foi possível carregar seus favoritos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _text, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => setState(_load),
                      icon: const Icon(Icons.refresh_rounded),
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: _palette.cardAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite_border_rounded,
                        color: _palette.primaryForeground,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Sua lista está vazia',
                      style: TextStyle(
                        color: _text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Toque no coração de um ponto de coleta para salvá-lo aqui.',
                      style: TextStyle(color: _muted, height: 1.45, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seus lugares',
                          style: TextStyle(
                            color: _text,
                            fontSize: 25,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pontos de coleta que você quer ter por perto.',
                          style: TextStyle(color: _muted, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _palette.cardAccent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_rounded, size: 15, color: _palette.primaryForeground),
                        const SizedBox(width: 6),
                        Text(
                          '${items.length}',
                          style: TextStyle(
                            color: _palette.primaryForeground,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              ...items.map((item) {
                final rawData = item['data'];
                final data = rawData is Map
                    ? Map<String, dynamic>.from(rawData)
                    : <String, dynamic>{};
                final title = (data['nome'] ?? 'Ponto de coleta').toString();
                final subtitle = (data['endereco'] ?? 'Endereço não informado').toString();
                final origin = (data['origem'] ?? 'Público').toString();
                final types = data['tipos_residuos'] is List
                    ? List<String>.from(data['tipos_residuos'])
                    : <String>[];

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _palette.border.withValues(alpha: 0.75)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.045),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      onTap: () => _openInGoogleMaps(data),
                      borderRadius: BorderRadius.circular(22),
                      child: Padding(
                        padding: const EdgeInsets.all(17),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: _palette.cardAccent,
                                    borderRadius: BorderRadius.circular(17),
                                  ),
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    color: _palette.primaryForeground,
                                    size: 25,
                                  ),
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'PONTO DE COLETA',
                                          style: TextStyle(
                                            color: _palette.primaryForeground,
                                            fontSize: 9,
                                            letterSpacing: 1.05,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: _text,
                                            fontSize: 15,
                                            height: 1.2,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  tooltip: 'Remover dos favoritos',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: item['id'] is num
                                      ? () => _remove(
                                            item['type'].toString(),
                                            (item['id'] as num).toInt(),
                                          )
                                      : null,
                                  style: IconButton.styleFrom(
                                    backgroundColor: _palette.cardAccent,
                                    foregroundColor: _palette.primaryForeground,
                                  ),
                                  icon: const Icon(Icons.favorite_rounded, size: 19),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.near_me_outlined, size: 16, color: _muted),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _muted,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (types.isNotEmpty) ...[
                              const SizedBox(height: 15),
                              Divider(height: 1, color: _palette.border.withValues(alpha: 0.7)),
                              const SizedBox(height: 12),
                              Text(
                                'ACEITA',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 9,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 7,
                                runSpacing: 7,
                                children: types.take(4).map((type) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: _palette.cardAccent,
                                      borderRadius: BorderRadius.circular(10),
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
                            const SizedBox(height: 15),
                            Container(
                              height: 1,
                              color: _palette.border.withValues(alpha: 0.7),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.account_balance_outlined, size: 15, color: _muted),
                                const SizedBox(width: 7),
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
                                Text(
                                  'Ver rota',
                                  style: TextStyle(
                                    color: _palette.primaryForeground,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: _palette.primaryForeground,
                                ),
                              ],
                            ),
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
