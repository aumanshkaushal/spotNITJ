import 'package:home_widget/home_widget.dart';

class WidgetUpdater {
  static Future<void> update({
    required int seats,

    required int capacity,

    required String details,

    required String rawJson,
  }) async {
    final occupied = capacity - seats;

    final percent = capacity == 0 ? 0 : ((occupied / capacity) * 100).round();

    final filled = (percent / 10).round();

    final dots = List.generate(8, (i) => i < filled ? '●' : '○').join(' ');

    final level = percent <= 50
        ? 'GREEN'
        : percent <= 75
        ? 'YELLOW'
        : 'RED';

    await HomeWidget.saveWidgetData('seats', seats);

    await HomeWidget.saveWidgetData('details', details);

    await HomeWidget.saveWidgetData('dots', dots);

    await HomeWidget.saveWidgetData('level', level);

    await HomeWidget.saveWidgetData('capacity', capacity);

    await HomeWidget.saveWidgetData('rawJson', rawJson);
  }
}
