import 'package:flutter/material.dart';

import '../models.dart';
import '../trip_controller.dart';
import '../ui_format.dart';
import 'trip_details_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({
    super.key,
    required this.controller,
    required this.currentUserEmail,
  });

  final TripController controller;
  final String currentUserEmail;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late Future<List<Trip>> _trips;

  @override
  void initState() {
    super.initState();
    _trips = widget.controller.api.fetchAdminTrips();
  }

  Future<void> _refresh() async {
    final future = widget.controller.api.fetchAdminTrips();
    setState(() => _trips = future);
    try {
      await future;
    } catch (_) {
      // Eroarea este afișată de FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Administrare')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: FutureBuilder<List<Trip>>(
              future: _trips,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 80),
                      Icon(
                        Icons.cloud_off,
                        size: 56,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Călătoriile nu au putut fi încărcate.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: FilledButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reîncearcă'),
                        ),
                      ),
                    ],
                  );
                }

                final trips = snapshot.data ?? const [];
                if (trips.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 100),
                      Icon(
                        Icons.people_outline,
                        size: 56,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nu există călătorii înregistrate.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: trips.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Toate călătoriile',
                              style: theme.textTheme.titleLarge,
                            ),
                            Text(
                              '${trips.length} călătorii de la toți '
                              'utilizatorii',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }
                    final trip = trips[index - 1];
                    return _AdminTripCard(
                      trip: trip,
                      isMine:
                          trip.ownerEmail == widget.currentUserEmail,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TripDetailsScreen(
                              controller: widget.controller,
                              trip: trip,
                              remote: true,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminTripCard extends StatelessWidget {
  const _AdminTripCard({
    required this.trip,
    required this.isMine,
    required this.onTap,
  });

  final Trip trip;
  final bool isMine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = _statusLabel(trip.status);
    final chipColor = switch (trip.status) {
      TripStatus.completed => scheme.primaryContainer,
      TripStatus.active => scheme.tertiaryContainer,
      TripStatus.cancelled => scheme.errorContainer,
      TripStatus.interrupted => scheme.surfaceContainerHighest,
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: isMine
                    ? scheme.primaryContainer
                    : scheme.secondaryContainer,
                child: Text(
                  _initials(trip.ownerEmail),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMine
                          ? '${trip.ownerEmail} (tu)'
                          : trip.ownerEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatDateTime(trip.startedAt)} • '
                      '${formatDistance(trip.distanceMeters)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '${formatDuration(trip.totalDurationSeconds)} • '
                      '${formatSpeed(trip.averageSpeedMps)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                visualDensity: VisualDensity.compact,
                backgroundColor: chipColor,
                side: BorderSide.none,
                label: Text(label, style: theme.textTheme.labelSmall),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _initials(String email) {
    final name = email.split('@').first.replaceAll(
          RegExp(r'[^a-zA-Z0-9]'),
          '',
        );
    if (name.isEmpty) {
      return '?';
    }
    return name.length == 1
        ? name.toUpperCase()
        : name.substring(0, 2).toUpperCase();
  }

  static String _statusLabel(TripStatus status) {
    switch (status) {
      case TripStatus.active:
        return 'activă';
      case TripStatus.completed:
        return 'finalizată';
      case TripStatus.cancelled:
        return 'anulată';
      case TripStatus.interrupted:
        return 'întreruptă';
    }
  }
}
