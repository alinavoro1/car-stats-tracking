import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models.dart';
import '../trip_controller.dart';
import '../trip_stats.dart';
import '../ui_format.dart';
import '../widgets/stat_card.dart';

class TripDetailsScreen extends StatefulWidget {
  const TripDetailsScreen({
    super.key,
    required this.controller,
    required this.trip,
    this.remote = false,
  });

  final TripController controller;
  final Trip trip;

  /// Când este true, punctele se încarcă din endpointul de admin.
  final bool remote;

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  late Future<_DetailsData> _details;

  @override
  void initState() {
    super.initState();
    _details = _load();
  }

  Future<_DetailsData> _load() async {
    final points = widget.remote
        ? await widget.controller.api.fetchAdminTripPoints(widget.trip.id)
        : await widget.controller.loadPoints(widget.trip.id);
    final analysis = analyzeTrip(
      points,
      startedAt: widget.trip.startedAt,
      endedAt: widget.trip.endedAt,
    );
    return _DetailsData(points: points, analysis: analysis);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trip = widget.trip;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalii călătorie')),
      body: FutureBuilder<_DetailsData>(
        future: _details,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Detaliile nu au putut fi încărcate.',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final analysis = data.analysis;
          final points = analysis.validPoints;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(formatDateTime(trip.startedAt)),
                  subtitle: Text(
                    trip.endedAt == null
                        ? 'Fără oră de finalizare'
                        : 'Până la ${formatDateTime(trip.endedAt!)}',
                  ),
                ),
              ),
              if (widget.remote && trip.ownerEmail.isNotEmpty) ...[
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Proprietar'),
                    subtitle: Text(trip.ownerEmail),
                  ),
                ),
              ],
              if (trip.status == TripStatus.cancelled) ...[
                const SizedBox(height: 8),
                Text(
                  'Călătorie anulată – exclusă din statistici.',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              if (trip.syncState == SyncState.failed &&
                  trip.syncError != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Sincronizare eșuată: ${trip.syncError}',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.9,
                children: [
                  StatCard(
                    label: 'Distanță',
                    value: formatDistance(analysis.distanceMeters),
                    icon: Icons.route,
                  ),
                  StatCard(
                    label: 'Durată totală',
                    value: formatDuration(analysis.totalDurationSeconds),
                    icon: Icons.timer_outlined,
                  ),
                  StatCard(
                    label: 'Timp de deplasare',
                    value: formatDuration(analysis.movingDurationSeconds),
                    icon: Icons.directions_car,
                  ),
                  StatCard(
                    label: 'Staționare estimată',
                    value: formatDuration(analysis.stationaryDurationSeconds),
                    icon: Icons.pause_circle_outline,
                  ),
                  StatCard(
                    label: 'Viteză medie',
                    value: formatSpeed(analysis.averageSpeedMps),
                    icon: Icons.speed,
                  ),
                  StatCard(
                    label: 'Viteză maximă',
                    value: formatSpeed(analysis.maxSpeedMps),
                    icon: Icons.trending_up,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Traseu', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (points.isEmpty)
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Nu există puncte GPS valide pentru acest traseu.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                )
              else
                _TripMap(points: points),
              const SizedBox(height: 12),
              Text(
                '${points.length} puncte GPS valide din ${data.points.length} '
                'colectate.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Viteza medie este calculată ca distanța parcursă împărțită '
                'la timpul efectiv de deplasare.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailsData {
  const _DetailsData({required this.points, required this.analysis});

  final List<GpsPoint> points;
  final AnalysisResult analysis;
}

class _TripMap extends StatelessWidget {
  const _TripMap({required this.points});

  final List<GpsPoint> points;

  @override
  Widget build(BuildContext context) {
    final coordinates = points
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList(growable: false);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 300,
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.coordinates(
              coordinates: coordinates,
              padding: const EdgeInsets.all(36),
              maxZoom: 16,
            ),
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
                    strokeWidth: 4,
                    color: Colors.blue.shade700,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: coordinates.first,
                  width: 36,
                  height: 36,
                  child: const Icon(
                    Icons.trip_origin,
                    color: Colors.green,
                    size: 30,
                    semanticLabel: 'Start',
                  ),
                ),
                if (coordinates.length > 1)
                  Marker(
                    point: coordinates.last,
                    width: 36,
                    height: 36,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 32,
                      semanticLabel: 'Sosire',
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
    );
  }
}
