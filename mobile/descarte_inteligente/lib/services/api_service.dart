import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import '../models/collection_point.dart';

class ApiService {
  static const Duration _requestTimeout = Duration(seconds: 15);

  static Future<dynamic> _getJson(
    Uri uri, {
    required String errorMessage,
  }) async {
    late http.Response response;

    try {
      response = await http.get(uri).timeout(_requestTimeout);
    } on TimeoutException {
      throw Exception('A solicitação demorou demais. Tente novamente.');
    } on SocketException {
      throw Exception(
        'Não foi possível conectar ao servidor. Verifique sua conexão.',
      );
    } on http.ClientException {
      throw Exception(
        'Falha na comunicação com o servidor. Tente novamente.',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        throw Exception('O servidor retornou uma resposta inválida.');
      }
      decoded = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final detail = decoded is Map<String, dynamic>
        ? decoded['detail']?.toString()
        : null;

    throw Exception(
      detail?.isNotEmpty == true
          ? detail
          : '$errorMessage (${response.statusCode})',
    );
  }

  static Future<String> testConnection() async {
    final data = await _getJson(
      Uri.parse('${ApiConstants.baseUrl}/api/test'),
      errorMessage: 'Erro ao testar a conexão com a API',
    );

    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }

    throw Exception('Resposta inesperada ao testar a conexão com a API.');
  }

  static Future<List<CollectionPoint>> getCollectionPoints() async {
    final data = await _getJson(
      Uri.parse('${ApiConstants.baseUrl}/api/collection-points'),
      errorMessage: 'Erro ao buscar pontos de coleta',
    );

    if (data is! List) {
      throw Exception('Formato inválido na lista de pontos de coleta.');
    }

    return data
        .map((json) => CollectionPoint.fromJson(
              Map<String, dynamic>.from(json as Map),
            ))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getNearbyCollectionPoints(
    double latitude,
    double longitude,
  ) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/api/collection-points/nearby',
    ).replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      },
    );

    final data = await _getJson(
      uri,
      errorMessage: 'Erro ao buscar pontos próximos',
    );

    if (data is! List) {
      throw Exception('Formato inválido na lista de pontos próximos.');
    }

    return data
        .map((point) => Map<String, dynamic>.from(point as Map))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getWasteTypes() async {
    final data = await _getJson(
      Uri.parse('${ApiConstants.baseUrl}/api/waste-types'),
      errorMessage: 'Erro ao buscar resíduos',
    );

    if (data is! List) {
      throw Exception('Formato inválido na lista de resíduos.');
    }

    return data
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> searchWasteTypes(
    String query,
  ) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/api/waste-types/search',
    ).replace(
      queryParameters: {'q': query},
    );

    final data = await _getJson(
      uri,
      errorMessage: 'Erro ao pesquisar resíduos',
    );

    if (data is! List) {
      throw Exception('Formato inválido na pesquisa de resíduos.');
    }

    return data
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<Map<String, dynamic>> getWasteType(int wasteId) async {
    final data = await _getJson(
      Uri.parse('${ApiConstants.baseUrl}/api/waste-types/$wasteId'),
      errorMessage: 'Erro ao buscar resíduo',
    );

    if (data is! Map) {
      throw Exception('Formato inválido nos dados do resíduo.');
    }

    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> sendChatMessage(
    String message, {
    List<Map<String, String>> history = const [],
    double? latitude,
    double? longitude,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiConstants.baseUrl}/api/chat'),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({
            'message': message,
            'history': history,
            if (latitude != null && longitude != null) ...{
              'latitude': latitude,
              'longitude': longitude,
            },
          }),
        )
        .timeout(const Duration(seconds: 45));

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(decoded);
    }

    final detail = decoded is Map<String, dynamic>
        ? decoded['detail']?.toString()
        : null;

    throw Exception(
      detail ?? 'Erro ao enviar mensagem: ${response.statusCode}',
    );
  }

  static Future<List<Map<String, dynamic>>> getCollectionPointsForWaste(
    int wasteId,
  ) async {
    final data = await _getJson(
      Uri.parse(
        '${ApiConstants.baseUrl}/api/waste-types/$wasteId/collection-points',
      ),
      errorMessage: 'Erro ao buscar pontos compatíveis',
    );

    if (data is! List) {
      throw Exception('Formato inválido na lista de pontos compatíveis.');
    }

    return data
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}
