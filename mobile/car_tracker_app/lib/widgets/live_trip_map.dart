import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models.dart';

/// Harta traseului în timpul călătoriei active.
class LiveTripMap extends StatefulWidget {
  const LiveTripMap({
    super.key,
    required this.points,
    this.height = 280,
  });

  final List<GpsPoint> points;
  final double height;

  @override
  State<LiveTripMap> createState() => _LiveTripMapState();
}

class _LiveTripMapState extends State<LiveTripMap> {
  final MapController _mapController = MapController();
  bool _ready = false;

  @override
  void didUpdateWidget(covariant LiveTripMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ready || widget.points.isEmpty) {
      return;
    }
    final lastId = widget.points.last.id;
    final previousId =
        oldWidget.points.isEmpty ? null : oldWidget.points.last.id;
    if (lastId == previousId) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_ready) {
        return;
      }
      final last = widget.points.last;
      _mapController.move(
        LatLng(last.latitude, last.longitude),
        _mapController.camera.zoom,
      );
    });
  }

  void _centerOnLast() {
    if (!_ready || widget.points.isEmpty) {
      return;
    }
    final last = widget.points.last;
    _mapController.move(LatLng(last.latitude, last.longitude), 16);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.points.isEmpty) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.gps_off,
                size: 36,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 8),
              Text(
                'Se așteaptă poziția GPS...',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final coordinates = widget.points
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList(growable: false);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: coordinates.last,
                  initialZoom: 16,
                  onMapReady: () => _ready = true,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.car_tracker_app',
                  ),
                  if (coordinates.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: coordinates,
                          strokeWidth: 5,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: coordinates.last,
                        width: 44,
                        height: 44,
                        child: _CurrentPositionMarker(
                          color: theme.colorScheme.primary,
                          onColor: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SimpleAttributionWidget(
                    source: Text('OpenStreetMap contributors'),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: theme.colorScheme.surface,
                shape: const CircleBorder(),
                elevation: 2,
                child: IconButton(
                  tooltip: 'Centrează poziția',
                  onPressed: _centerOnLast,
                  icon: Icon(
                    Icons.my_location,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentPositionMarker extends StatelessWidget {
  const _CurrentPositionMarker({
    required this.color,
    required this.onColor,
  });

  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Poziția curentă',
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(Icons.navigation_rounded, color: onColor, size: 20),
      ),
    );
  }
}
