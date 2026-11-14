import 'package:flutter/material.dart';

enum AppNotificationType {
  success,
  info,
  warning,
  error,
}

/// Exibe notificações padronizadas com a identidade visual do aplicativo.
class AppNotification {
  AppNotification._();

  static const _surface = Color(0xFF0D202B);
  static const _text = Color(0xFFF2F8FA);
  static const _green = Color(0xFF55D6A2);
  static const _cyan = Color(0xFF53D9F5);
  static const _orange = Color(0xFFFFB45C);
  static const _red = Color(0xFFFF7777);

  static void show(
    BuildContext context,
    String message, {
    AppNotificationType type = AppNotificationType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          duration: duration,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          content: _NotificationCard(
            message: message,
            type: type,
          ),
        ),
      );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.message,
    required this.type,
  });

  final String message;
  final AppNotificationType type;

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon, String title) = switch (type) {
      AppNotificationType.success => (
          AppNotification._green,
          Icons.check_circle_outline_rounded,
          'Concluído',
        ),
      AppNotificationType.info => (
          AppNotification._cyan,
          Icons.info_outline_rounded,
          'Informação',
        ),
      AppNotificationType.warning => (
          AppNotification._orange,
          Icons.warning_amber_rounded,
          'Atenção',
        ),
      AppNotificationType.error => (
          AppNotification._red,
          Icons.error_outline_rounded,
          'Ocorreu um erro',
        ),
    };

    return Material(
      color: AppNotification._surface,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.48)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(
                      color: AppNotification._text,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
