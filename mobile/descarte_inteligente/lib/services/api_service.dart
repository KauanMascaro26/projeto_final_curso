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
      final data = jsonDecode(response.body);
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
      final List<dynamic> data = jsonDecode(response.body);

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
      final List<dynamic> data = jsonDecode(response.body);

      return data
          .map((point) => Map<String, dynamic>.from(point))
          .toList();
    }

    throw Exception(
      'Erro ao buscar pontos próximos: ${response.statusCode}',
    );
  }
}