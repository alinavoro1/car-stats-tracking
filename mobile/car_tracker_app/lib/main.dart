import 'package:flutter/material.dart';

import 'api_client.dart';
import 'database.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'trip_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await AppDatabase.open();
  final controller = TripController(db: database, api: ApiClient());
  await controller.initialize();
  runApp(CarTrackerApp(controller: controller));
}

class CarTrackerApp extends StatelessWidget {
  const CarTrackerApp({super.key, required this.controller});

  final TripController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20)),
        useMaterial3: true,
      ),
      home: HomeShell(controller: controller),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final TripController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardScreen(controller: widget.controller),
          HistoryScreen(controller: widget.controller),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Acasă',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Istoric',
          ),
        ],
      ),
    );
  }
}
