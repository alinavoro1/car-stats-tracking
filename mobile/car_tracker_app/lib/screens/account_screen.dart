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
    final user = auth.user;
    final active = controller.activeTrip;
    return Scaffold(
      appBar: AppBar(title: const Text('Cont')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.email ?? '—',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    avatar: Icon(
                      user?.isAdmin == true
                          ? Icons.admin_panel_settings
                          : Icons.person_outline,
                      size: 18,
                    ),
                    label: Text(
                      user?.isAdmin == true ? 'Administrator' : 'Utilizator',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (active != null) ...[
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.route),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ai o călătorie activă. După o nouă autentificare '
                        'cu acest cont o poți continua.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: const ListTile(
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
              foregroundColor: theme.colorScheme.error,
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Ieși din cont'),
          ),
        ],
      ),
    );
  }
}
