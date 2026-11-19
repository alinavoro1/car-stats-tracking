import 'dart:async';

import 'package:flutter/material.dart';

import '../trip_controller.dart';
import '../ui_format.dart';

class ActiveTripScreen extends StatefulWidget {
  const ActiveTripScreen({super.key, required this.controller});

  final TripController controller;

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  Timer? _clock;
  bool _stopping = false;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _stopTrip() async {
    final confirmed = await _confirm(
      title: 'Oprești călătoria?',
      message: 'Înregistrarea GPS se oprește, iar statisticile sunt calculate.',
      actionLabel: 'Oprește',
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _stopping = true);
    final error = await widget.controller.stopTrip();
    if (!mounted) {
      return;
    }
    setState(() => _stopping = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _cancelTrip() async {
    final confirmed = await _confirm(
      title: 'Anulezi călătoria?',
      message: 'Călătoria este marcată ca anulată și nu apare în statistici.',
      actionLabel: 'Anulează călătoria',
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final error = await widget.controller.cancelTrip();
    if (!mounted) {
      return;
    }
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _resume() async {
    final error = await widget.controller.resumeTracking();
    if (!mounted || error == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message)),
    );
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String actionLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Renunță'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final trip = widget.controller.activeTrip;
        if (trip == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Călătorie')),
            body: const Center(child: Text('Nu există o călătorie activă.')),
          );
        }

        final elapsed = DateTime.now().difference(trip.startedAt);
        final analysis = widget.controller.liveAnalysis;
        final validPoints = analysis?.validPoints ?? const [];
        final lastPoint = validPoints.isEmpty ? null : validPoints.last;
        final speed = lastPoint?.speedMps;
        final active = widget.controller.isTracking;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Călătorie activă'),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'cancel') {
                    _cancelTrip();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'cancel',
                    child: Text('Anulează călătoria'),
                  ),
                ],
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: active
                            ? [
                                scheme.primary,
                                Color.lerp(
                                  scheme.primary,
                                  scheme.tertiary,
                                  0.3,
                                )!,
                              ]
                            : [
                                scheme.surfaceContainerHighest,
                                scheme.surfaceContainerHighest,
                              ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: active
                                ? Colors.lightGreenAccent
                                : Colors.orangeAccent,
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: Colors.lightGreenAccent
                                          .withValues(alpha: 0.6),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                active ? 'Tracking activ' : 'Tracking oprit',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: active
                                      ? scheme.onPrimary
                                      : scheme.onSurface,
                                ),
                              ),
                              Text(
                                active
                                    ? 'Notificarea persistentă este vizibilă.'
                                    : 'Poți relua înregistrarea.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: active
                                      ? scheme.onPrimary.withValues(alpha: 0.8)
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!active) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Înregistrarea GPS nu rulează. Poți continua '
                              'călătoria sau o poți finaliza.',
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _resume,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Continuă înregistrarea'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (widget.controller.gpsError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.controller.gpsError!,
                      style: TextStyle(color: scheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Column(
                    children: [
                      Text(
                        formatClock(elapsed),
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          fontFeatures: const [
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                      Text(
                        'durata călătoriei',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _LiveValue(
                                  label: 'Distanță',
                                  value: formatDistance(
                                    analysis?.distanceMeters ?? 0,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _LiveValue(
                                  label: 'Viteză curentă',
                                  value: speed == null
                                      ? '—'
                                      : formatSpeed(speed),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(height: 1),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _LiveValue(
                                  label: 'Viteză maximă',
                                  value: formatSpeed(
                                    analysis?.maxSpeedMps ?? 0,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _LiveValue(
                                  label: 'Puncte GPS',
                                  value:
                                      '${widget.controller.activePoints.length}',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _stopping ? null : _stopTrip,
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                    ),
                    icon: _stopping
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.stop_rounded),
                    label: Text(
                      _stopping ? 'Se oprește...' : 'Oprește călătoria',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Înregistrarea este vizibilă prin notificarea '
                    'persistentă și poate fi oprită oricând.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LiveValue extends StatelessWidget {
  const _LiveValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
