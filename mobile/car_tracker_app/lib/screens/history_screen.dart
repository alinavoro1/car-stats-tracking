import 'package:flutter/material.dart';

import '../models.dart';
import '../trip_controller.dart';
import '../ui_format.dart';
import 'trip_details_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.controller});

  final TripController controller;

  Future<void> _retry(BuildContext context, Trip trip) async {
    final error = await controller.syncTrip(trip);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Sincronizare reușită.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Istoric călătorii')),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final trips = controller.historyTrips;
          return RefreshIndicator(
            onRefresh: controller.refreshHistory,
            child: trips.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 100),
                      Icon(
                        Icons.route_outlined,
                        size: 56,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nu există călătorii înregistrate.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pornește o călătorie din ecranul principal.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: trips.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: trip.status == TripStatus.cancelled
                              ? theme.colorScheme.surfaceContainerHighest
                              : theme.colorScheme.primaryContainer,
                          child: Icon(
                            trip.status == TripStatus.cancelled
                                ? Icons.cancel_outlined
                                : Icons.directions_car,
                          ),
                        ),
                        title: Text(formatDateTime(trip.startedAt)),
                        subtitle: Text(
                          '${formatDistance(trip.distanceMeters)} • '
                          '${formatDuration(trip.totalDurationSeconds)} • '
                          '${formatSpeed(trip.averageSpeedMps)}'
                          '${trip.status == TripStatus.cancelled ? ' • anulată' : ''}',
                        ),
                        trailing: trip.status == TripStatus.completed
                            ? _SyncIndicator(
                                trip: trip,
                                onRetry: () => _retry(context, trip),
                              )
                            : null,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => TripDetailsScreen(
                                controller: controller,
                                trip: trip,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

class _SyncIndicator extends StatelessWidget {
  const _SyncIndicator({required this.trip, required this.onRetry});

  final Trip trip;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    switch (trip.syncState) {
      case SyncState.synced:
        return Icon(
          Icons.cloud_done,
          color: Colors.green.shade700,
          semanticLabel: 'Sincronizată',
        );
      case SyncState.syncing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case SyncState.pending:
        return Icon(
          Icons.cloud_upload_outlined,
          color: theme.colorScheme.outline,
          semanticLabel: 'În așteptare',
        );
      case SyncState.failed:
        return IconButton(
          onPressed: onRetry,
          icon: Icon(Icons.cloud_off, color: theme.colorScheme.error),
          tooltip: trip.syncError ?? 'Reîncearcă sincronizarea',
        );
    }
  }
}
