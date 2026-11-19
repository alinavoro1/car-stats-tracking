import 'package:flutter/material.dart';

import '../models.dart';
import '../trip_controller.dart';
import '../ui_format.dart';
import 'trip_details_screen.dart';

const _months = [
  'ian',
  'feb',
  'mar',
  'apr',
  'mai',
  'iun',
  'iul',
  'aug',
  'sep',
  'oct',
  'nov',
  'dec',
];

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
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: trips.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        children: [
                          const SizedBox(height: 96),
                          CircleAvatar(
                            radius: 36,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.route_outlined,
                              size: 36,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 16),
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
                        padding: const EdgeInsets.all(16),
                        itemCount: trips.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final trip = trips[index];
                          return _TripCard(
                            trip: trip,
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
                            trailing: trip.status == TripStatus.completed
                                ? _SyncIndicator(
                                    trip: trip,
                                    onRetry: () => _retry(context, trip),
                                  )
                                : const Icon(Icons.chevron_right),
                          );
                        },
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.onTap,
    required this.trailing,
  });

  final Trip trip;
  final VoidCallback onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = trip.startedAt.toLocal();
    final cancelled = trip.status == TripStatus.cancelled;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: cancelled
                      ? theme.colorScheme.surfaceContainerHighest
                      : theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${local.day}'.padLeft(2, '0'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cancelled
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      _months[local.month - 1],
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cancelled
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${local.hour.toString().padLeft(2, '0')}:'
                          '${local.minute.toString().padLeft(2, '0')}',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(width: 8),
                        if (cancelled)
                          Chip(
                            visualDensity: VisualDensity.compact,
                            label: const Text('anulată'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatDistance(trip.distanceMeters)} • '
                      '${formatDuration(trip.totalDurationSeconds)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      'Viteză medie ${formatSpeed(trip.averageSpeedMps)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
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
          color: theme.colorScheme.primary,
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
