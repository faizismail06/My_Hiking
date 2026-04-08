import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:myhiking/models/model.dart';

class TrailPreviewScreen extends StatelessWidget {
  final String trailName;
  final RoutePreview? routePreview;
  final double? basecampLatitude;
  final double? basecampLongitude;
  final List<TrailPost> posts;

  const TrailPreviewScreen({
    super.key,
    required this.trailName,
    required this.routePreview,
    this.basecampLatitude,
    this.basecampLongitude,
    this.posts = const [],
  });

  @override
  Widget build(BuildContext context) {
    final preview = routePreview;
    final hasRoute = preview != null && preview.points.isNotEmpty;

    if (!hasRoute) {
      return Scaffold(
        appBar: AppBar(title: Text('Preview Jalur $trailName')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Data preview jalur belum tersedia. Silakan upload GPX terlebih dahulu dari panel admin atau penjaga jalur.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final polylinePoints =
        preview.points.map((point) => LatLng(point.lat, point.lng)).toList();
    final latValues = polylinePoints.map((point) => point.latitude).toList();
    final lngValues = polylinePoints.map((point) => point.longitude).toList();
    final minLat = latValues.reduce((a, b) => a < b ? a : b);
    final maxLat = latValues.reduce((a, b) => a > b ? a : b);
    final minLng = lngValues.reduce((a, b) => a < b ? a : b);
    final maxLng = lngValues.reduce((a, b) => a > b ? a : b);
    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

    final latSpan = (maxLat - minLat).abs();
    final lngSpan = (maxLng - minLng).abs();
    final maxSpan = latSpan > lngSpan ? latSpan : lngSpan;

    double initialZoom;
    if (maxSpan > 1) {
      initialZoom = 9;
    } else if (maxSpan > 0.5) {
      initialZoom = 10;
    } else if (maxSpan > 0.2) {
      initialZoom = 11;
    } else if (maxSpan > 0.1) {
      initialZoom = 12;
    } else if (maxSpan > 0.05) {
      initialZoom = 13;
    } else if (maxSpan > 0.02) {
      initialZoom = 14;
    } else {
      initialZoom = 15;
    }

    final markers = <Marker>[
      Marker(
        point: polylinePoints.first,
        width: 42,
        height: 42,
        child:
            _buildPin(Icons.play_circle_fill, Colors.green.shade600, 'Start'),
      ),
      Marker(
        point: polylinePoints.last,
        width: 42,
        height: 42,
        child: _buildPin(Icons.flag_circle, Colors.red.shade600, 'Finish'),
      ),
    ];

    if (basecampLatitude != null && basecampLongitude != null) {
      markers.add(
        Marker(
          point: LatLng(basecampLatitude!, basecampLongitude!),
          width: 42,
          height: 42,
          child: _buildPin(
            Icons.home_work_rounded,
            Colors.blue.shade700,
            'Basecamp',
          ),
        ),
      );
    }

    for (var i = 0; i < posts.length; i++) {
      markers.add(
        Marker(
          point: LatLng(posts[i].lat, posts[i].lng),
          width: 46,
          height: 46,
          child: _buildPosPin(posts[i], i + 1),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Preview Jalur $trailName'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: initialZoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.myhiking.app',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: polylinePoints,
                      strokeWidth: 7,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    Polyline(
                      points: polylinePoints,
                      strokeWidth: 4.5,
                      color: const Color(0xFF117958),
                    ),
                  ],
                ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildLegendItem(
                      icon: Icons.play_circle_fill,
                      color: Colors.green.shade600,
                      label: 'Start',
                    ),
                    _buildLegendItem(
                      icon: Icons.flag_circle,
                      color: Colors.red.shade600,
                      label: 'Finish',
                    ),
                    _buildLegendItem(
                      icon: Icons.home_work_rounded,
                      color: Colors.blue.shade700,
                      label: 'Basecamp',
                    ),
                    _buildLegendItem(
                      icon: Icons.signpost_rounded,
                      color: Colors.orange.shade700,
                      label: posts.isEmpty
                          ? 'Pos (belum diinput)'
                          : 'Pos (${posts.length})',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPin(IconData icon, Color color, String semanticLabel) {
    return Semantics(
      label: semanticLabel,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }

  Widget _buildPosPin(TrailPost post, int fallbackIndex) {
    final index = post.sequence > 0 ? post.sequence : fallbackIndex;
    final semanticLabel = post.name.isNotEmpty ? post.name : 'Pos $index';

    return Semantics(
      label: semanticLabel,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.orange.shade700,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '$index',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
