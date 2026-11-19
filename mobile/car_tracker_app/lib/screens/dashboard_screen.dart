import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models.dart';
import '../trip_controller.dart';
import '../ui_format.dart';
import '../widgets/stat_card.dart';
import 'active_trip_screen.dart';
import 'trip_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.controller,
    required this.userEmail,
  });

  final TripController controller;
  final String userEmail;

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
                error.openLocationSettings
                    ? 'Setări locație'
                    : 'Setări aplicație',
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
      appBar: AppBar(
        title: const Text('Car Tracker'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.directions_car,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
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
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    _hero(theme, controller, activeTrip),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            label: 'Călătorii finalizate',
                            value: '${controller.completedTrips.length}',
                            icon: Icons.check_circle_outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            label: 'Ultima călătorie',
                            value: lastTrip == null
                                ? '—'
                                : formatDateTime(lastTrip.startedAt)
                                    .split(' ')
                                    .first,
                            icon: Icons.event_outlined,
                          ),
                        ),
                      ],
                    ),
                    if (lastTrip != null) ...[
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                            child: Icon(
                              Icons.route,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
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
                      const SizedBox(height: 12),
                      Card(
                        color: theme.colorScheme.tertiaryContainer,
                        child: ListTile(
                          leading: Icon(
                            Icons.cloud_off,
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                          title: Text(
                            '${unsynced.length} călătorii nesincronizate',
                            style: TextStyle(
                              color: theme.colorScheme.onTertiaryContainer,
                            ),
                          ),
                          trailing: TextButton(
                            onPressed: _syncNow,
                            child: const Text('Sincronizează'),
                          ),
                        ),
                      ),
                    ],
                    if (controller.gpsError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        controller.gpsError!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                        leading: const Icon(Icons.tune),
                        title: const Text('Diagnostic'),
                        subtitle: const Text(
                          'Conexiune server și poziția GPS',
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          16,
                        ),
                        expandedCrossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed:
                                _checkingBackend ? null : _checkBackend,
                            icon: _checkingBackend
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.cloud_sync),
                            label: const Text(
                              'Verifică conexiunea la server',
                            ),
                          ),
                          if (_backendMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _backendMessage!,
                                style: TextStyle(
                                  color: _backendOk == true
                                      ? theme.colorScheme.primary
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.gps_fixed),
                            label: const Text('Verifică GPS'),
                          ),
                          if (sample != null) ...[
                            const SizedBox(height: 12),
                            _GpsSampleCard(position: sample),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _hero(
    ThemeData theme,
    TripController controller,
    Trip? activeTrip,
  ) {
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, scheme.tertiary, 0.35)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: scheme.onPrimary.withValues(alpha: 0.16),
                child: Icon(Icons.directions_car, color: scheme.onPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bun venit,',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onPrimary.withValues(alpha: 0.75),
                      ),
                    ),
                    Text(
                      widget.userEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (activeTrip != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
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
                        Icons.circle,
                        size: 9,
                        color: controller.isTracking
                            ? Colors.lightGreenAccent
                            : Colors.orangeAccent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        controller.isTracking ? 'activ' : 'pauză',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            formatDistance(controller.totalDistanceMeters),
            style: theme.textTheme.displaySmall?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          Text(
            'distanță totală',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onPrimary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.onPrimary,
                foregroundColor: scheme.primary,
              ),
              onPressed: activeTrip != null
                  ? _openActiveTrip
                  : (_starting ? null : _startTrip),
              icon: activeTrip != null
                  ? const Icon(Icons.navigation_rounded)
                  : (_starting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.primary,
                          ),
                        )
                      : const Icon(Icons.play_arrow_rounded)),
              label: Text(
                activeTrip != null
                    ? 'Deschide călătoria activă'
                    : (_starting
                        ? 'Se pornește...'
                        : 'Pornește călătoria'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GpsSampleCard extends StatelessWidget {
  const _GpsSampleCard({required this.position});

  final Position position;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final speed = position.hasSpeed
        ? '${(position.speed * 3.6).toStringAsFixed(0)} km/h'
        : 'indisponibilă';
    final altitude = position.hasAltitude
        ? '${position.altitude.toStringAsFixed(0)} m'
        : '—';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Poziție curentă', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
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
    );
  }
}
