import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';

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
}