import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../auth_controller.dart';
import '../trip_controller.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    required this.auth,
    required this.controller,
  });

  final AuthController auth;
  final TripController controller;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with WidgetsBindingObserver {
  PermissionStatus? _locationAlwaysStatus;
  PermissionStatus? _locationWhenInUseStatus;
  PermissionStatus? _notificationStatus;
  bool _loadingPermissions = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Permisiunile pot fi schimbate în timp ce aplicația este în fundal.
    if (state == AppLifecycleState.resumed) {
      _loadPermissions();
    }
  }

  Future<void> _loadPermissions() async {
    if (!_loadingPermissions) {
      setState(() => _loadingPermissions = true);
    }
    PermissionStatus? locationAlways;
    PermissionStatus? locationWhenInUse;
    PermissionStatus? notification;
    try {
      locationAlways = await Permission.locationAlways.status;
      locationWhenInUse = await Permission.locationWhenInUse.status;
      notification = await Permission.notification.status;
    } catch (_) {
      // Unele platforme (sau testele) nu oferă aceste informații.
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _locationAlwaysStatus = locationAlways;
      _locationWhenInUseStatus = locationWhenInUse;
      _notificationStatus = notification;
      _loadingPermissions = false;
    });
  }

  Future<void> _openAppSettings() async {
    await widget.controller.openAppSettings();
    await _loadPermissions();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ieși din cont?'),
        content: const Text(
          'Datele locale rămân pe dispozitiv. O călătorie aflată în '
          'desfășurare va fi oprită, dar nu se pierde.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Renunță'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Ieși din cont'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.auth.logout();
    }
  }

  String get _locationLabel {
    final always = _locationAlwaysStatus;
    if (always == null) {
      return 'Se verifică…';
    }
    if (always.isGranted) {
      return 'Întotdeauna';
    }
    if (_locationWhenInUseStatus?.isGranted ?? false) {
      return 'Doar în timpul utilizării';
    }
    return _statusLabel(always);
  }

  Color _locationColor(ColorScheme scheme) {
    final always = _locationAlwaysStatus;
    if (always == null) {
      return scheme.onSurfaceVariant;
    }
    if (always.isGranted) {
      return scheme.primary;
    }
    if (_locationWhenInUseStatus?.isGranted ?? false) {
      return scheme.tertiary;
    }
    return _statusColor(always, scheme);
  }

  String get _notificationLabel => _notificationStatus == null
      ? 'Se verifică…'
      : _statusLabel(_notificationStatus!);

  Color _notificationColor(ColorScheme scheme) => _notificationStatus == null
      ? scheme.onSurfaceVariant
      : _statusColor(_notificationStatus!, scheme);

  String _statusLabel(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Permisă';
      case PermissionStatus.denied:
        return 'Neacordată';
      case PermissionStatus.permanentlyDenied:
        return 'Refuzată permanent';
      case PermissionStatus.restricted:
        return 'Restricționată';
      case PermissionStatus.limited:
        return 'Acces limitat';
      case PermissionStatus.provisional:
        return 'Provizorie';
    }
  }

  Color _statusColor(PermissionStatus status, ColorScheme scheme) {
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.provisional:
        return scheme.primary;
      case PermissionStatus.restricted:
      case PermissionStatus.limited:
        return scheme.tertiary;
      case PermissionStatus.denied:
      case PermissionStatus.permanentlyDenied:
        return scheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = widget.auth.user;
    final active = widget.controller.activeTrip;
    final isAdmin = user?.isAdmin == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Cont')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary,
                      Color.lerp(scheme.primary, scheme.tertiary, 0.35)!,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor:
                          scheme.onPrimary.withValues(alpha: 0.18),
                      child: Icon(
                        Icons.person,
                        size: 44,
                        color: scheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.email ?? '—',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.onPrimary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAdmin
                                ? Icons.admin_panel_settings
                                : Icons.person_outline,
                            size: 18,
                            color: scheme.onPrimary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAdmin ? 'Administrator' : 'Utilizator',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (active != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: scheme.tertiaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.route,
                          color: scheme.onTertiaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ai o călătorie activă. După o nouă '
                            'autentificare cu acest cont o poți continua.',
                            style: TextStyle(
                              color: scheme.onTertiaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Card(
                child: const ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: Icon(Icons.info_outline),
                  title: Text('Datele rămân pe dispozitiv'),
                  subtitle: Text(
                    'Călătoriile nesincronizate nu sunt șterse la logout.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shield_outlined, color: scheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Permisiuni',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Actualizează',
                            onPressed:
                                _loadingPermissions ? null : _loadPermissions,
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _PermissionRow(
                        icon: Icons.location_on_outlined,
                        label: 'Locație',
                        status: _locationLabel,
                        color: _locationColor(scheme),
                      ),
                      const SizedBox(height: 8),
                      _PermissionRow(
                        icon: Icons.notifications_outlined,
                        label: 'Notificări',
                        status: _notificationLabel,
                        color: _notificationColor(scheme),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Locația este necesară pentru înregistrarea '
                        'călătoriilor, iar notificările pentru notificarea '
                        'persistentă de urmărire.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _openAppSettings,
                        icon: const Icon(Icons.settings_outlined),
                        label: const Text('Deschide setările aplicației'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.error,
                ),
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Ieși din cont'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.label,
    required this.status,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 2),
              Text(
                status,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
