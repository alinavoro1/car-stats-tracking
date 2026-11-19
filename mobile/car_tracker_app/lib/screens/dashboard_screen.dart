import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models.dart';
import '../trip_controller.dart';
import '../ui_format.dart';
import '../widgets/stat_card.dart';
import 'active_trip_screen.dart';
import 'trip_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.controller});

  final TripController controller;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _starting = false;
  bool _checkingBackend = false;
  bool _checkingGps = false;
  bool? _backendOk;
  String? _backendMessage;

  Future<void> _startTrip() async {
    setState(() => _starting = true);
    final error = await widget.controller.startTrip();
    if (!mounted) {
      return;
    }
    setState(() => _starting = false);
    if (error != null) {
      await _showTrackingProblem(error);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ActiveTripScreen(controller: widget.controller),
      ),
    );
  }

  Future<void> _showTrackingProblem(TripStartError error) async {
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nu pot porni înregistrarea'),
        content: Text(error.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Închide'),
          ),
          if (error.openLocationSettings || error.openAppSettings)
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                error.openLocationSettings ? 'Setări locație' : 'Setări aplicație',
              ),
            ),
        ],
      ),
    );
    if (openSettings != true) {
      return;
    }
    if (error.openLocationSettings) {
      await widget.controller.openLocationSettings();
    } else {
      await widget.controller.openAppSettings();
    }
  }

  Future<void> _openActiveTrip() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ActiveTripScreen(controller: widget.controller),
      ),
    );
  }

  Future<void> _openDetails(Trip trip) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TripDetailsScreen(
          controller: widget.controller,
          trip: trip,
        ),
      ),
    );
  }

  Future<void> _checkBackend() async {
    setState(() {
      _checkingBackend = true;
      _backendMessage = null;
    });
    final error = await widget.controller.checkBackend();
    if (!mounted) {
      return;
    }
    setState(() {
      _checkingBackend = false;
      _backendOk = error == null;
      _backendMessage = error ?? 'Conexiune reușită.';
    });
  }

  Future<void> _checkGps() async {
    setState(() => _checkingGps = true);
    final error = await widget.controller.checkGps();
    if (!mounted) {
      return;
    }
    setState(() => _checkingGps = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  Future<void> _syncNow() async {
    final error = await widget.controller.syncPendingTrips();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Sincronizare finalizată.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Car Tracker')),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;
          final activeTrip = controller.activeTrip;
          final lastTrip = controller.lastTrip;
          final unsynced = controller.unsyncedTrips;
          final sample = controller.lastGpsSample;

          return RefreshIndicator(
            onRefresh: controller.refreshHistory,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (activeTrip != null) ...[
                  Card(
                    color: theme.colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.fiber_manual_record,
                                color: controller.isTracking
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  controller.isTracking
                                      ? 'Tracking activ'
                                      : 'Călătorie activă (GPS oprit)',
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pornită la ${formatDateTime(activeTrip.startedAt)}',
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonalIcon(
                            onPressed: _openActiveTrip,
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Deschide călătoria'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: activeTrip != null || _starting ? null : _startTrip,
                    icon: _starting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(
                      _starting ? 'Se pornește...' : 'Pornește călătoria',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Distanță totală',
                        value: formatDistance(controller.totalDistanceMeters),
                        icon: Icons.route,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Călătorii finalizate',
                        value: '${controller.completedTrips.length}',
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                  ],
                ),
                if (lastTrip != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('Ultima călătorie'),
                      subtitle: Text(
                        '${formatDateTime(lastTrip.startedAt)} • '
                        '${formatDistance(lastTrip.distanceMeters)} • '
                        '${formatDuration(lastTrip.totalDurationSeconds)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openDetails(lastTrip),
                    ),
                  ),
                ],
                if (unsynced.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: ListTile(
                      leading: const Icon(Icons.cloud_off),
                      title: Text(
                        '${unsynced.length} călătorii nesincronizate',
                      ),
                      trailing: TextButton(
                        onPressed: _syncNow,
                        child: const Text('Sincronizează'),
                      ),
                    ),
                  ),
                ],
                if (controller.gpsError != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    controller.gpsError!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                Text('Diagnostic', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _checkingBackend ? null : _checkBackend,
                  icon: _checkingBackend
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_sync),
                  label: const Text('Verifică conexiunea la server'),
                ),
                if (_backendMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _backendMessage!,
                      style: TextStyle(
                        color: _backendOk == true
                            ? Colors.green.shade700
                            : theme.colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _checkingGps ? null : _checkGps,
                  icon: _checkingGps
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.gps_fixed),
                  label: const Text('Verifică GPS'),
                ),
                if (sample != null) ...[
                  const SizedBox(height: 8),
                  _GpsSampleCard(position: sample),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GpsSampleCard extends StatelessWidget {
  const _GpsSampleCard({required this.position});

  final Position position;

  @override
  Widget build(BuildContext context) {
    final speed = position.hasSpeed
        ? '${(position.speed * 3.6).toStringAsFixed(0)} km/h'
        : 'indisponibilă';
    final altitude =
        position.hasAltitude ? '${position.altitude.toStringAsFixed(0)} m' : '—';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Poziție curentă',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${position.latitude.toStringAsFixed(6)}, '
              '${position.longitude.toStringAsFixed(6)}',
            ),
            Text('Acuratețe: ${position.accuracy.toStringAsFixed(1)} m'),
            Text('Viteză GPS: $speed'),
            Text('Altitudine: $altitude'),
            Text('Timp: ${formatDateTime(position.timestamp)}'),
          ],
        ),
      ),
    );
  }
}
