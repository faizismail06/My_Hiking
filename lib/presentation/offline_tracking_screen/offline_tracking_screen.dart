import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/utils/web_file_downloader_stub.dart'
    if (dart.library.html) '../../core/utils/web_file_downloader_web.dart';

class OfflineTrackingScreen extends StatefulWidget {
  final int orderId;
  final String mountainName;

  const OfflineTrackingScreen({
    super.key,
    required this.orderId,
    required this.mountainName,
  });

  @override
  State<OfflineTrackingScreen> createState() => _OfflineTrackingScreenState();
}

class _OfflineTrackingScreenState extends State<OfflineTrackingScreen> {
  final MapController _mapController = MapController();
  final Distance _distance = const Distance();

  List<LatLng> _gpxRoutePoints = [];
  List<LatLng> _trackedPoints = [];

  StreamSubscription<Position>? _positionSubscription;
  Position? _currentPosition;

  bool _isUploadingGpx = false;
  bool _isTracking = false;
  double _trackedDistanceMeters = 0;
  DateTime? _trackingStartedAt;
  String? _selectedGpxName;

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  Future<Directory> _resolveExportDirectory() async {
    if (kIsWeb) {
      throw Exception('Platform web menggunakan mekanisme download browser');
    }

    if (Platform.isAndroid) {
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
      }

      if (!status.isGranted) {
        throw Exception('Izin penyimpanan ditolak');
      }

      final downloadDir = Directory('/storage/emulated/0/Download');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      return downloadDir;
    }

    return getApplicationDocumentsDirectory();
  }

  LatLng _currentMapCenter() {
    if (_currentPosition != null) {
      return LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    }

    if (_trackedPoints.isNotEmpty) {
      return _trackedPoints.last;
    }

    if (_gpxRoutePoints.isNotEmpty) {
      return _gpxRoutePoints.first;
    }

    return const LatLng(-7.4, 110.4);
  }

  List<LatLng> _parseGpxPoints(String gpxContent) {
    final tagRegex = RegExp(
      r'<(?:trkpt|rtept)\b[^>]*>',
      caseSensitive: false,
      multiLine: true,
    );

    final points = <LatLng>[];
    for (final match in tagRegex.allMatches(gpxContent)) {
      final tag = match.group(0) ?? '';
      final lat = _extractAttribute(tag, 'lat');
      final lon = _extractAttribute(tag, 'lon');
      if (lat == null || lon == null) {
        continue;
      }

      final latVal = double.tryParse(lat);
      final lonVal = double.tryParse(lon);
      if (latVal == null || lonVal == null) {
        continue;
      }

      if (latVal < -90 || latVal > 90 || lonVal < -180 || lonVal > 180) {
        continue;
      }

      points.add(LatLng(latVal, lonVal));
    }

    return points;
  }

  String? _extractAttribute(String tag, String key) {
    final attrRegex = RegExp(
      """$key\\s*=\\s*["']([^"']+)["']""",
      caseSensitive: false,
    );
    final match = attrRegex.firstMatch(tag);
    return match?.group(1);
  }

  Future<void> _uploadGpx() async {
    setState(() {
      _isUploadingGpx = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['gpx', 'xml'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes ??
          (!kIsWeb && file.path != null
              ? await File(file.path!).readAsBytes()
              : null);

      if (bytes == null || bytes.isEmpty) {
        throw Exception('File GPX tidak terbaca');
      }

      final content = utf8.decode(bytes, allowMalformed: true);
      final parsedPoints = _parseGpxPoints(content);

      if (parsedPoints.length < 2) {
        throw Exception('File GPX minimal harus memiliki 2 titik jalur');
      }

      setState(() {
        _gpxRoutePoints = parsedPoints;
        _selectedGpxName = file.name;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitMapToAllPoints();
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('GPX berhasil dimuat (${parsedPoints.length} titik)'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal upload GPX: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingGpx = false;
        });
      }
    }
  }

  Future<bool> _ensureLocationReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) {
        return false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Layanan lokasi tidak aktif. Mohon aktifkan GPS.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) {
        return false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Izin lokasi dibutuhkan untuk tracking offline.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _startTracking() async {
    if (_isTracking) {
      return;
    }

    final isReady = await _ensureLocationReady();
    if (!isReady) {
      return;
    }

    try {
      final current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      final firstPoint = LatLng(current.latitude, current.longitude);

      setState(() {
        _currentPosition = current;
        _isTracking = true;
        _trackingStartedAt ??= DateTime.now();
        if (_trackedPoints.isEmpty) {
          _trackedPoints.add(firstPoint);
        }
      });

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 5,
        ),
      ).listen((position) {
        final nextPoint = LatLng(position.latitude, position.longitude);

        setState(() {
          _currentPosition = position;

          if (_trackedPoints.isNotEmpty) {
            final previousPoint = _trackedPoints.last;
            _trackedDistanceMeters += _distance.as(
              LengthUnit.Meter,
              previousPoint,
              nextPoint,
            );
          }

          _trackedPoints.add(nextPoint);
        });
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitMapToAllPoints();
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memulai tracking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    if (mounted) {
      setState(() {
        _isTracking = false;
      });
    }
  }

  void _resetTracking() {
    setState(() {
      _trackedPoints = [];
      _trackedDistanceMeters = 0;
      _trackingStartedAt = null;
      _currentPosition = null;
    });
  }

  String _buildTrackedGpx() {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final buffer = StringBuffer();

    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="MyHiking Offline Tracker" xmlns="http://www.topografix.com/GPX/1/1">');
    buffer.writeln('  <metadata>');
    buffer.writeln('    <name>${_escapeXml('Tracking ${widget.mountainName}')}</name>');
    buffer.writeln('    <time>$nowIso</time>');
    buffer.writeln('  </metadata>');
    buffer.writeln('  <trk>');
    buffer.writeln('    <name>${_escapeXml('Track ${widget.orderId}')}</name>');
    buffer.writeln('    <trkseg>');

    for (final point in _trackedPoints) {
      buffer.writeln('      <trkpt lat="${point.latitude}" lon="${point.longitude}" />');
    }

    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');
    buffer.writeln('</gpx>');

    return buffer.toString();
  }

  Future<void> _exportTrackedGpx() async {
    if (_trackedPoints.length < 2) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tracking belum cukup. Minimal 2 titik untuk disimpan.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final content = _buildTrackedGpx();
      final fileName = 'tracking_offline_order_${widget.orderId}_${DateTime.now().millisecondsSinceEpoch}.gpx';

      if (kIsWeb) {
        await downloadTextFileOnWeb(
          fileName: fileName,
          content: content,
          mimeType: 'application/gpx+xml',
        );

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Track berhasil diekspor lewat browser'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      final directory = await _resolveExportDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(content, flush: true);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Track tersimpan di: ${file.path}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal ekspor track: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _fitMapToAllPoints() {
    final all = <LatLng>[..._gpxRoutePoints, ..._trackedPoints];

    if (_currentPosition != null) {
      all.add(LatLng(_currentPosition!.latitude, _currentPosition!.longitude));
    }

    if (all.isEmpty) {
      return;
    }

    if (all.length == 1) {
      _mapController.move(all.first, 15);
      return;
    }

    final bounds = LatLngBounds.fromPoints(all);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(40),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = _trackingStartedAt == null
        ? Duration.zero
        : DateTime.now().difference(_trackingStartedAt!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking Offline & Kompas'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        StreamBuilder<CompassEvent>(
                          stream: FlutterCompass.events,
                          builder: (context, snapshot) {
                            final heading = snapshot.data?.heading ?? 0;
                            return Column(
                              children: [
                                Transform.rotate(
                                  angle: -heading * (math.pi / 180),
                                  child: const Icon(
                                    Icons.navigation,
                                    color: Colors.teal,
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${heading.toStringAsFixed(0)}°',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.mountainName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedGpxName == null
                                    ? 'Belum ada GPX yang diupload'
                                    : 'GPX: $_selectedGpxName',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tracking: ${_isTracking ? 'AKTIF' : 'NONAKTIF'} | Durasi: ${_formatDuration(elapsed)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _isTracking
                                      ? Colors.green.shade700
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isUploadingGpx ? null : _uploadGpx,
                        icon: _isUploadingGpx
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.upload_file),
                        label: const Text('Upload GPX'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _fitMapToAllPoints,
                        icon: const Icon(Icons.center_focus_strong),
                        label: const Text('Fit Peta'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isTracking ? _stopTracking : _startTracking,
                        icon: Icon(_isTracking ? Icons.pause : Icons.play_arrow),
                        label: Text(_isTracking ? 'Stop Tracking' : 'Start Tracking'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _resetTracking,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _exportTrackedGpx,
                        icon: const Icon(Icons.download),
                        label: const Text('Simpan Track'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Jarak track: ${(_trackedDistanceMeters / 1000).toStringAsFixed(2)} km',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text('Titik: ${_trackedPoints.length}'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentMapCenter(),
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.myhiking.app',
                ),
                if (_gpxRoutePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _gpxRoutePoints,
                        color: Colors.teal,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                if (_trackedPoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _trackedPoints,
                        color: Colors.blue,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (_currentPosition != null)
                      Marker(
                        point: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        width: 44,
                        height: 44,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.red,
                          size: 30,
                        ),
                      ),
                    if (_gpxRoutePoints.isNotEmpty)
                      Marker(
                        point: _gpxRoutePoints.first,
                        width: 36,
                        height: 36,
                        child: const Icon(
                          Icons.play_circle_fill,
                          color: Colors.green,
                          size: 28,
                        ),
                      ),
                    if (_gpxRoutePoints.length > 1)
                      Marker(
                        point: _gpxRoutePoints.last,
                        width: 36,
                        height: 36,
                        child: const Icon(
                          Icons.flag_circle,
                          color: Colors.orange,
                          size: 28,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.black.withValues(alpha: 0.03),
            child: const Text(
              'Tracking tetap berjalan dengan GPS walau internet terbatas. Peta mungkin tidak tampil penuh saat benar-benar offline.',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
