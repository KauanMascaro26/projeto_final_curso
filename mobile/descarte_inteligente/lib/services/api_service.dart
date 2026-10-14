import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import '../models/collection_point.dart';

class ApiService {
  static Future<String> testConnection() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/test'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['message'];
    }

    throw Exception(
      'Erro na API: ${response.statusCode}',
    );
  }

  static Future<List<CollectionPoint>> getCollectionPoints() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/collection-points'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

      return data
          .map((json) => CollectionPoint.fromJson(json))
          .toList();
    }

    throw Exception(
      'Erro ao buscar pontos de coleta: ${response.statusCode}',
    );
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

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

      return data
          .map((point) => Map<String, dynamic>.from(point))
          .toList();
    }

    throw Exception(
      'Erro ao buscar pontos próximos: ${response.statusCode}',
    );
  }

  static Future<List<Map<String, dynamic>>> getWasteTypes() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/waste-types'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

      return data
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    throw Exception(
      'Erro ao buscar resíduos: ${response.statusCode}',
    );
  }

  static Future<List<Map<String, dynamic>>> searchWasteTypes(
    String query,
  ) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/api/waste-types/search',
    ).replace(
      queryParameters: {'q': query},
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

      return data
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    throw Exception(
      'Erro ao pesquisar resíduos: ${response.statusCode}',
    );
  }

  static Future<Map<String, dynamic>> getWasteType(int wasteId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/waste-types/$wasteId'),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
    }

    throw Exception(
      'Erro ao buscar resíduo: ${response.statusCode}',
    );
  }
}
