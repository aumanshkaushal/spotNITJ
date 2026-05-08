import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:home_widget/home_widget.dart';

import 'models/floor_data.dart';
import 'services/api_service.dart';
import 'services/shared_state.dart';
import 'services/widget_updater.dart';

@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  await refreshWidget();
}

Future<void> refreshWidget() async {
  final data = await ApiService.fetchSeats();

  final seats = data['total'];

  final capacity = data['capacity'];

  final floors = data['floors'] as List<FloorData>;

  final rawJson = data['rawJson'];

  final details = floors
      .map((f) {
        final floor = f.floor
            .replaceAll('Ground Floor', 'GROUND')
            .replaceAll('Floor ', '');

        return '${f.availableSeats} IN $floor';
      })
      .join('\n');

  await WidgetUpdater.update(
    seats: seats,
    capacity: capacity,
    details: details,
    rawJson: rawJson,
  );

  await HomeWidget.updateWidget(androidName: 'SeatWidgetProvider');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    HomeWidget.registerInteractivityCallback(backgroundCallback);
  } catch (e) {
    debugPrint(e.toString());
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool loading = true;

  int seats = 0;

  int capacity = 390;

  List<FloorData> floors = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      load();
    }
  }

  Future<void> syncFromWidget() async {
    final data = await SharedState.load();

    seats = data['seats'];

    capacity = data['capacity'];

    floors = data['floors'];

    setState(() {});
  }

  Future<void> load() async {
    setState(() {
      loading = true;
    });

    try {
      await refreshWidget();

      await syncFromWidget();
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() {
      loading = false;
    });
  }

  Color getColor() {
    final occupied = capacity - seats;

    final percent = capacity == 0 ? 0 : ((occupied / capacity) * 100).round();

    if (percent <= 50) {
      return const Color(0xFF00FFB2);
    }

    if (percent <= 75) {
      return const Color(0xFFFFD60A);
    }

    return const Color(0xFFFF453A);
  }

  List<Widget> buildDots() {
    final occupied = capacity - seats;

    final percent = capacity == 0 ? 0 : ((occupied / capacity) * 100).round();

    final filled = (percent / 12.5).round();

    final color = getColor();

    return List.generate(8, (index) {
      final active = index < filled;

      return Container(
        margin: const EdgeInsets.only(right: 16),
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? color : Colors.transparent,
          border: Border.all(color: color, width: 2),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = getColor();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: load,
          color: color,
          backgroundColor: Colors.black,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 26),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LIBRARY',
                    style: GoogleFonts.vt323(
                      fontSize: 30,
                      color: Colors.white70,
                      letterSpacing: 2,
                    ),
                  ),

                  GestureDetector(
                    onTap: load,
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white70,
                      size: 26,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 65),

              Text(
                loading
                    ? 'LOADING'
                    : seats == 0
                    ? 'NO SEATS'
                    : '$seats SEATS',
                style: GoogleFonts.vt323(
                  fontSize: 72,
                  letterSpacing: 5,
                  color: color,
                  height: 1,
                ),
              ),

              const SizedBox(height: 42),

              Row(children: buildDots()),

              const SizedBox(height: 52),

              ...floors.map((floor) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 22),
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white10),
                  ),

                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),

                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,

                      iconColor: Colors.white70,
                      collapsedIconColor: Colors.white38,

                      title: Text(
                        '${floor.availableSeats} IN ${floor.floor.toUpperCase()}',
                        style: GoogleFonts.vt323(
                          fontSize: 34,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),

                      children: [
                        const SizedBox(height: 12),

                        Wrap(
                          spacing: 10,
                          runSpacing: 10,

                          children: floor.availableSeatIds.map((id) {
                            return Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,

                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white24),

                                borderRadius: BorderRadius.circular(12),
                              ),

                              child: Text(
                                id.toString().padLeft(2, '0'),

                                style: GoogleFonts.vt323(
                                  fontSize: 24,
                                  color: Colors.white70,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
