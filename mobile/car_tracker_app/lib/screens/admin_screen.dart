import 'package:flutter/material.dart';

import '../models.dart';
import '../trip_controller.dart';
import '../ui_format.dart';

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
              itemCount: trips.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final trip = trips[index];
                final isMine = trip.ownerEmail == widget.currentUserEmail;
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isMine
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.secondaryContainer,
                      child: Icon(
                        isMine
                            ? Icons.person
                            : Icons.directions_car_outlined,
                      ),
                    ),
                    title: Text(
                      isMine ? '${trip.ownerEmail} (tu)' : trip.ownerEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${formatDateTime(trip.startedAt)}\n'
                        '${formatDistance(trip.distanceMeters)} • '
                        '${formatDuration(trip.totalDurationSeconds)} • '
                        '${formatSpeed(trip.averageSpeedMps)}',
                      ),
                    ),
                    isThreeLine: true,
                    trailing: Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(_statusLabel(trip.status)),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _statusLabel(TripStatus status) {
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
