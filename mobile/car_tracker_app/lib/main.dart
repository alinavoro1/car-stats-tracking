import 'dart:async';

import 'package:flutter/material.dart';

import 'api_client.dart';
import 'auth_controller.dart';
import 'database.dart';
import 'screens/account_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'theme.dart';
import 'token_storage.dart';
import 'trip_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await AppDatabase.open();
  final api = ApiClient();
  final auth = AuthController(api: api, storage: TokenStorage());
  await auth.initialize();
  runApp(CarTrackerApp(database: database, api: api, auth: auth));
}

class CarTrackerApp extends StatelessWidget {
  const CarTrackerApp({
    super.key,
    required this.database,
    required this.api,
    required this.auth,
  });

  final AppDatabase database;
  final ApiClient api;
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car Tracker',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: _AuthGate(database: database, api: api, auth: auth),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate({
    required this.database,
    required this.api,
    required this.auth,
  });

  final AppDatabase database;
  final ApiClient api;
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        switch (auth.status) {
          case AuthStatus.unknown:
            return const _SplashScreen();
          case AuthStatus.unauthenticated:
            return LoginScreen(auth: auth);
          case AuthStatus.authenticated:
            final user = auth.user!;
            return _AuthenticatedHome(
              key: ValueKey(user.email),
              database: database,
              api: api,
              auth: auth,
            );
        }
      },
    );
  }
}

class _AuthenticatedHome extends StatefulWidget {
  const _AuthenticatedHome({
    super.key,
    required this.database,
    required this.api,
    required this.auth,
  });

  final AppDatabase database;
  final ApiClient api;
  final AuthController auth;

  @override
  State<_AuthenticatedHome> createState() => _AuthenticatedHomeState();
}

class _AuthenticatedHomeState extends State<_AuthenticatedHome> {
  late final TripController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TripController(
      db: widget.database,
      api: widget.api,
      ownerEmail: widget.auth.user!.email,
    );
    unawaited(_controller.initialize());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomeShell(controller: _controller, auth: widget.auth);
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_car_filled,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.controller,
    required this.auth,
  });

  final TripController controller;
  final AuthController auth;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = widget.auth.user;
    final isAdmin = user?.isAdmin ?? false;
    final screens = [
      DashboardScreen(
        controller: widget.controller,
        userEmail: user?.email ?? '',
      ),
      HistoryScreen(controller: widget.controller),
      if (isAdmin)
        AdminScreen(
          controller: widget.controller,
          currentUserEmail: user!.email,
        ),
      AccountScreen(auth: widget.auth, controller: widget.controller),
    ];
    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Acasă',
      ),
      const NavigationDestination(
        icon: Icon(Icons.history_outlined),
        selectedIcon: Icon(Icons.history),
        label: 'Istoric',
      ),
      if (isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Cont',
      ),
    ];
    final selectedIndex =
        _selectedIndex < screens.length ? _selectedIndex : 0;

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: destinations,
      ),
    );
  }
}
