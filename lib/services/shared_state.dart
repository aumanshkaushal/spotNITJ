import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import '../models/floor_data.dart';

class SharedState {
  static Future<Map<String, dynamic>> load() async {
    final rawJson =
        await HomeWidget.getWidgetData<String>('rawJson', defaultValue: '{}') ??
        '{}';

    final decoded = jsonDecode(rawJson);

    final seats = decoded['totalAvailableSeats'] ?? 0;

    final capacity = decoded['totalCapacity'] ?? 390;

    final floors =
        (decoded['capacity'] as List?)
            ?.map((e) => FloorData.fromJson(e))
            .toList() ??
        [];

    return {'seats': seats, 'capacity': capacity, 'floors': floors};
  }
}
