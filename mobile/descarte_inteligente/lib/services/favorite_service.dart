import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class FavoriteService {
  static const _key = 'descarte_inteligente_favorites';

  static Future<List<Map<String, dynamic>>> getAll() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> contains(String type, int id) async {
    final items = await getAll();
    return items.any((item) => item['type'] == type && item['id'] == id);
  }

  static Future<void> toggle({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final items = await getAll();
    final id = (data['id'] as num).toInt();
    final exists = items.any((item) => item['type'] == type && item['id'] == id);

    if (exists) {
      items.removeWhere((item) => item['type'] == type && item['id'] == id);
    } else {
      items.add({
        'type': type,
        'id': id,
        'data': data,
        'saved_at': DateTime.now().toIso8601String(),
      });
    }

    await preferences.setString(_key, jsonEncode(items));
  }

  static Future<void> remove(String type, int id) async {
    final preferences = await SharedPreferences.getInstance();
    final items = await getAll();
    items.removeWhere((item) => item['type'] == type && item['id'] == id);
    await preferences.setString(_key, jsonEncode(items));
  }
}
