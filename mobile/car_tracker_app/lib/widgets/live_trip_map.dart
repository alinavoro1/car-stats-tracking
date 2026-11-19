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
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
            const SimpleAttributionWidget(
              source: Text('OpenStreetMap contributors'),
            ),
          ],
        ),
      ),
    );
  }
}
