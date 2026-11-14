import 'package:flutter/foundation.dart';

class ApiConstants {
  // Em desenvolvimento, usa o IP local da máquina. Para release, informe
  // a URL pública HTTPS com --dart-define=API_BASE_URL=https://api.seudominio.com.
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.113:8000',
  );

  static String get baseUrl {
    final uri = Uri.tryParse(_configuredBaseUrl);
    if (uri == null || !uri.hasAuthority) {
      throw StateError('API_BASE_URL não contém uma URL válida.');
    }

    if (kReleaseMode && uri.scheme != 'https') {
      throw StateError(
        'A versão de produção exige API_BASE_URL com HTTPS. '
        'Gere o release informando --dart-define=API_BASE_URL=https://seu-dominio.',
      );
    }

    return _configuredBaseUrl;
  }
}
