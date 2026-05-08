import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/floor_data.dart';

class ApiService {
  static Future<Map<String, dynamic>> fetchSeats() async {
    final res = await http.get(
      Uri.parse('https://api.opensourcenitj.com/library/getSeats'),
    );

    final data = jsonDecode(res.body);

    final total = data['totalAvailableSeats'];

    final capacity = data['totalCapacity'];

    final floors = (data['capacity'] as List)
        .map((e) => FloorData.fromJson(e))
        .where((e) => e.availableSeats > 0)
        .toList();

    return {
      'total': total,
      'capacity': capacity,
      'floors': floors,
      'rawJson': jsonEncode(data),
    };
  }
}
