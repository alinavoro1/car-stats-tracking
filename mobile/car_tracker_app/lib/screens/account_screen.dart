import 'package:flutter/material.dart';

import '../auth_controller.dart';
import '../trip_controller.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({
    super.key,
    required this.auth,
    required this.controller,
  });

  final AuthController auth;
  final TripController controller;

  Future<void> _logout(BuildContext context) async {
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
      await auth.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = auth.user;
    final active = controller.activeTrip;
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
              const SizedBox(height: 24),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.error,
                ),
                onPressed: () => _logout(context),
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
