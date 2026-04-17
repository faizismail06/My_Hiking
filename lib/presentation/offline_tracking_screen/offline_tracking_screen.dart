import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../api/api_service.dart';
import '../../core/app_export.dart';
import '../../core/utils/web_file_downloader_stub.dart'
    if (dart.library.html) '../../core/utils/web_file_downloader_web.dart';
import 'bloc/offline_tracking_cubit.dart';
import 'bloc/offline_tracking_state.dart';

enum _OfflineMenuAction {
  uploadGpx,
  fitMap,
  exportTrack,
  syncCache,
  resetTrack,
}

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
  final OfflineTrackingCubit _cubit = OfflineTrackingCubit();
  final Connectivity _connectivity = Connectivity();
  final ApiService _apiService = ApiService();

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isPreparingLocation = false;
  bool _isOfflineMapUnlocked = false;
  bool _isSyncingCachedTracks = false;
  int _pendingCacheCount = 0;
  String _syncInfo = 'Cache lokal kosong';

  OfflineTrackingState get _state => _cubit.state;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrapCacheAndConnectivity());
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _cubit.close();
    super.dispose();
  }

  Future<void> _bootstrapCacheAndConnectivity() async {
    await _refreshPendingCacheCount();
    unawaited(_syncCachedTracksIfPossible(showSnackBar: false));

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((_) {
      unawaited(_syncCachedTracksIfPossible(showSnackBar: false));
    });
  }

  void _showSnack(
    String message, {
    Color backgroundColor = Colors.black87,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
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

  Future<File> _resolvePendingQueueFile() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${baseDir.path}/offline_tracking_cache');

    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    return File('${cacheDir.path}/pending_tracks.json');
  }

  Future<List<Map<String, dynamic>>> _readPendingQueue() async {
    if (kIsWeb) {
      return const [];
    }

    try {
      final file = await _resolvePendingQueueFile();
      if (!await file.exists()) {
        return const [];
      }

      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return const [];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => item.map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writePendingQueue(List<Map<String, dynamic>> queue) async {
    if (kIsWeb) {
      return;
    }

    final file = await _resolvePendingQueueFile();
    await file.writeAsString(
      jsonEncode(queue),
      flush: true,
    );
  }

  Future<void> _refreshPendingCacheCount() async {
    final queue = await _readPendingQueue();
    if (!mounted) {
      return;
    }

    setState(() {
      _pendingCacheCount = queue.length;
      if (queue.isNotEmpty) {
        _syncInfo = 'Cache lokal tersedia ($_pendingCacheCount antrean).';
      }
    });
  }

  Future<bool> _hasInternetConnection() async {
    final connectivity = await _connectivity.checkConnectivity();
    final hasNetwork =
        connectivity.any((item) => item != ConnectivityResult.none);

    if (!hasNetwork) {
      return false;
    }

    if (kIsWeb) {
      return true;
    }

    try {
      final lookup = await InternetAddress.lookup('example.com').timeout(
        const Duration(seconds: 3),
      );
      return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _cacheCurrentTrackForSync({
    bool showSnackBar = true,
  }) async {
    if (_state.trackedPoints.length < 2) {
      return;
    }

    if (kIsWeb) {
      if (showSnackBar) {
        _showSnack(
          'Mode web tidak memiliki cache file lokal. Gunakan Simpan GPX.',
          backgroundColor: Colors.orange,
        );
      }
      return;
    }

    try {
      final queue = await _readPendingQueue();
      final elapsed = _state.trackingStartedAt == null
          ? Duration.zero
          : DateTime.now().difference(_state.trackingStartedAt!);

      queue.add({
        'cache_id':
            '${widget.orderId}_${DateTime.now().millisecondsSinceEpoch}',
        'order_id': widget.orderId,
        'mountain_name': widget.mountainName,
        'cached_at': DateTime.now().toIso8601String(),
        'point_count': _state.trackedPoints.length,
        'distance_meters': _state.trackedDistanceMeters,
        'duration_seconds': elapsed.inSeconds,
        'gpx_content': _buildTrackedGpx(),
      });

      await _writePendingQueue(queue);
      if (!mounted) {
        return;
      }

      setState(() {
        _pendingCacheCount = queue.length;
        _syncInfo =
            'Track disimpan ke cache lokal ($_pendingCacheCount antrean).';
      });

      if (showSnackBar) {
        _showSnack(
          'Track disimpan ke cache HP. Akan coba sinkron saat internet tersedia.',
          backgroundColor: Colors.green,
        );
      }

      unawaited(_syncCachedTracksIfPossible(showSnackBar: false));
    } catch (e) {
      _showSnack(
        'Gagal menyimpan cache lokal: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _sendCacheItemToServer(Map<String, dynamic> item) async {
    final token = await _apiService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token login tidak tersedia.');
    }

    final orderId = item['order_id'];
    final url = Uri.parse('$baseUrl/orders/$orderId/offline-track-sync');

    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'source': 'mobile_offline_tracking',
            'cached_at': item['cached_at'],
            'point_count': item['point_count'],
            'distance_meters': item['distance_meters'],
            'duration_seconds': item['duration_seconds'],
            'gpx_content': item['gpx_content'],
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> _syncCachedTracksIfPossible({
    required bool showSnackBar,
  }) async {
    if (kIsWeb || _isSyncingCachedTracks) {
      return;
    }

    final queue = await _readPendingQueue();
    if (queue.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        _pendingCacheCount = 0;
        if (!_state.isTracking) {
          _syncInfo = 'Cache lokal kosong';
        }
      });
      return;
    }

    final isOnline = await _hasInternetConnection();
    if (!isOnline) {
      if (!mounted) {
        return;
      }

      setState(() {
        _pendingCacheCount = queue.length;
        _syncInfo =
            'Tidak ada internet. Cache aman ($_pendingCacheCount antrean).';
      });

      if (showSnackBar) {
        _showSnack(
          'Masih offline. Data tetap tersimpan di cache HP.',
          backgroundColor: Colors.orange,
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isSyncingCachedTracks = true;
        _syncInfo = 'Sinkronisasi cache sedang berjalan...';
      });
    }

    final remaining = <Map<String, dynamic>>[];
    var syncedCount = 0;
    var endpointUnavailable = false;

    for (var i = 0; i < queue.length; i++) {
      final item = queue[i];
      try {
        await _sendCacheItemToServer(item);
        syncedCount++;
      } catch (e) {
        final err = e.toString().toLowerCase();
        if (err.contains('http 404') || err.contains('http 405')) {
          endpointUnavailable = true;
          remaining.addAll(queue.sublist(i));
          break;
        }
        remaining.add(item);
      }
    }

    await _writePendingQueue(remaining);
    if (!mounted) {
      return;
    }

    setState(() {
      _isSyncingCachedTracks = false;
      _pendingCacheCount = remaining.length;

      if (endpointUnavailable) {
        _syncInfo =
            'Endpoint sync backend belum tersedia. Cache tetap aman ($_pendingCacheCount antrean).';
      } else if (_pendingCacheCount == 0) {
        _syncInfo = 'Sinkronisasi selesai. Semua cache terkirim.';
      } else {
        _syncInfo =
            'Sebagian data belum terkirim ($_pendingCacheCount antrean).';
      }
    });

    if (showSnackBar) {
      if (endpointUnavailable) {
        _showSnack(
          'Backend sync belum tersedia. Data tetap disimpan lokal.',
          backgroundColor: Colors.orange,
        );
      } else if (syncedCount > 0 && _pendingCacheCount == 0) {
        _showSnack(
          'Sinkronisasi berhasil. $syncedCount cache track terkirim.',
          backgroundColor: Colors.green,
        );
      } else if (syncedCount > 0) {
        _showSnack(
          'Sinkron sebagian berhasil. Sisa cache: $_pendingCacheCount.',
          backgroundColor: Colors.orange,
        );
      }
    }
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
    if (_state.currentPosition != null) {
      return LatLng(
        _state.currentPosition!.latitude,
        _state.currentPosition!.longitude,
      );
    }

    if (_state.trackedPoints.isNotEmpty) {
      return _state.trackedPoints.last;
    }

    if (_state.gpxRoutePoints.isNotEmpty) {
      return _state.gpxRoutePoints.first;
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

  List<OfflineGpxWaypoint> _parseGpxWaypoints(String gpxContent) {
    final waypointRegex = RegExp(
      r'<wpt\b([^>]*)>([\s\S]*?)<\/wpt>|<wpt\b([^>]*)\/\s*>',
      caseSensitive: false,
      multiLine: true,
    );

    final waypoints = <OfflineGpxWaypoint>[];

    for (final match in waypointRegex.allMatches(gpxContent)) {
      final attributes = (match.group(1) ?? match.group(3) ?? '').trim();
      final innerContent = (match.group(2) ?? '').trim();

      final lat = _extractAttribute(attributes, 'lat');
      final lon = _extractAttribute(attributes, 'lon');

      final latVal = _parseCoordinate(lat);
      final lonVal = _parseCoordinate(lon);

      if (latVal == null || lonVal == null) {
        continue;
      }

      if (latVal < -90 || latVal > 90 || lonVal < -180 || lonVal > 180) {
        continue;
      }

      final parsedName = _extractElementText(innerContent, 'name');
      final parsedDescription = _extractElementText(innerContent, 'desc');

      waypoints.add(
        OfflineGpxWaypoint(
          point: LatLng(latVal, lonVal),
          name: parsedName ?? 'Pos ${waypoints.length + 1}',
          description: parsedDescription,
        ),
      );
    }

    return waypoints;
  }

  double? _parseCoordinate(String? value) {
    if (value == null) {
      return null;
    }

    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }

    return double.tryParse(normalized);
  }

  String? _extractAttribute(String tag, String key) {
    final attrRegex = RegExp(
      """$key\\s*=\\s*["']([^"']+)["']""",
      caseSensitive: false,
    );
    final match = attrRegex.firstMatch(tag);
    return match?.group(1);
  }

  String? _extractElementText(String content, String tagName) {
    if (content.trim().isEmpty) {
      return null;
    }

    final tagRegex = RegExp(
      '<$tagName\\b[^>]*>([\\s\\S]*?)<\\/$tagName>',
      caseSensitive: false,
      multiLine: true,
    );

    final match = tagRegex.firstMatch(content);
    if (match == null) {
      return null;
    }

    final rawText = (match.group(1) ?? '').replaceAll(RegExp(r'<[^>]+>'), '');
    final decoded = _decodeXmlText(rawText.trim());
    return decoded.isEmpty ? null : decoded;
  }

  String _decodeXmlText(String value) {
    return value
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&');
  }

  Future<void> _uploadGpx() async {
    _cubit.setUploading(true);

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
      final parsedWaypoints = _parseGpxWaypoints(content);

      if (parsedPoints.length < 2) {
        throw Exception('File GPX minimal harus memiliki 2 titik jalur');
      }

      _cubit.setGpxData(
        points: parsedPoints,
        waypoints: parsedWaypoints,
        fileName: file.name,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitMapToAllPoints();
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'GPX dimuat: ${parsedPoints.length} titik jalur, ${parsedWaypoints.length} titik pos.',
          ),
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
        _cubit.setUploading(false);
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

  Future<bool> _unlockOfflineMapWithLocation({
    bool showSnackBar = true,
  }) async {
    if (_isPreparingLocation) {
      return false;
    }

    setState(() {
      _isPreparingLocation = true;
    });

    try {
      final isReady = await _ensureLocationReady();
      if (!isReady) {
        return false;
      }

      final current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      _cubit.setCurrentPosition(current);

      if (mounted) {
        setState(() {
          _isOfflineMapUnlocked = true;
        });
      }

      _mapController.move(
        LatLng(current.latitude, current.longitude),
        15,
      );

      if (showSnackBar) {
        _showSnack(
          'Lokasi aktif. Offline map siap digunakan.',
          backgroundColor: Colors.green,
        );
      }

      return true;
    } catch (e) {
      _showSnack(
        'Gagal mengaktifkan lokasi: $e',
        backgroundColor: Colors.red,
      );
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isPreparingLocation = false;
        });
      }
    }
  }

  Future<void> _startTracking() async {
    if (_state.isTracking) {
      return;
    }

    if (_state.gpxRoutePoints.length < 2) {
      await _showUploadGpxRequiredDialog();
      return;
    }

    if (!_isOfflineMapUnlocked) {
      final unlocked = await _unlockOfflineMapWithLocation(showSnackBar: false);
      if (!unlocked) {
        return;
      }
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

      await _positionSubscription?.cancel();
      _cubit.startTracking(current: current, firstPoint: firstPoint);

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 5,
        ),
      ).listen((position) {
        final nextPoint = LatLng(position.latitude, position.longitude);
        var addedDistance = 0.0;

        if (_state.trackedPoints.isNotEmpty) {
          final previousPoint = _state.trackedPoints.last;
          addedDistance = _distance.as(
            LengthUnit.Meter,
            previousPoint,
            nextPoint,
          );
        }

        _cubit.appendTrackedPoint(
          position: position,
          point: nextPoint,
          addedDistanceMeters: addedDistance,
        );
      }, onError: (error) {
        _showSnack(
          'Update GPS bermasalah: $error',
          backgroundColor: Colors.red,
        );
      });

      if (mounted) {
        setState(() {
          _syncInfo = 'Tracking aktif. Data akan dicache saat stop.';
        });
      }

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
      _cubit.stopTracking();
    }

    await _cacheCurrentTrackForSync(showSnackBar: true);
  }

  Future<void> _resetTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    if (_state.trackedPoints.length >= 2) {
      await _cacheCurrentTrackForSync(showSnackBar: false);
    }

    _cubit.resetTracking();

    if (mounted) {
      setState(() {
        if (_pendingCacheCount > 0) {
          _syncInfo = 'Track direset. Cache masih $_pendingCacheCount antrean.';
        } else {
          _syncInfo = 'Track direset.';
        }
      });
    }
  }

  String _buildTrackedGpx() {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final buffer = StringBuffer();

    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
        '<gpx version="1.1" creator="MyHiking Offline Tracker" xmlns="http://www.topografix.com/GPX/1/1">');
    buffer.writeln('  <metadata>');
    buffer.writeln(
        '    <name>${_escapeXml('Tracking ${widget.mountainName}')}</name>');
    buffer.writeln('    <time>$nowIso</time>');
    buffer.writeln('  </metadata>');
    buffer.writeln('  <trk>');
    buffer.writeln('    <name>${_escapeXml('Track ${widget.orderId}')}</name>');
    buffer.writeln('    <trkseg>');

    for (final point in _state.trackedPoints) {
      buffer.writeln(
          '      <trkpt lat="${point.latitude}" lon="${point.longitude}" />');
    }

    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');
    buffer.writeln('</gpx>');

    return buffer.toString();
  }

  Future<void> _exportTrackedGpx() async {
    if (_state.trackedPoints.length < 2) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Tracking belum cukup. Minimal 2 titik untuk disimpan.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final content = _buildTrackedGpx();
      final fileName =
          'tracking_offline_order_${widget.orderId}_${DateTime.now().millisecondsSinceEpoch}.gpx';

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

  Future<void> _onMenuActionSelected(_OfflineMenuAction action) async {
    switch (action) {
      case _OfflineMenuAction.uploadGpx:
        await _uploadGpx();
        break;
      case _OfflineMenuAction.fitMap:
        _fitMapToAllPoints();
        break;
      case _OfflineMenuAction.exportTrack:
        await _exportTrackedGpx();
        break;
      case _OfflineMenuAction.syncCache:
        await _syncCachedTracksIfPossible(showSnackBar: true);
        break;
      case _OfflineMenuAction.resetTrack:
        await _resetTracking();
        break;
    }
  }

  void _fitMapToAllPoints() {
    final all = <LatLng>[
      ..._state.gpxRoutePoints,
      ..._state.gpxWaypoints.map((waypoint) => waypoint.point),
      ..._state.trackedPoints,
    ];

    if (_state.currentPosition != null) {
      all.add(
        LatLng(
          _state.currentPosition!.latitude,
          _state.currentPosition!.longitude,
        ),
      );
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

  IconData _primaryActionIcon(OfflineTrackingState state) {
    if (!_isOfflineMapUnlocked) {
      return Icons.location_searching;
    }
    return state.isTracking
        ? Icons.stop_circle_outlined
        : Icons.play_arrow_rounded;
  }

  String _primaryActionLabel(OfflineTrackingState state) {
    if (!_isOfflineMapUnlocked) {
      return 'Aktifkan Lokasi & Buka Offline Map';
    }
    return state.isTracking
        ? 'Stop Tracking & Simpan ke Cache'
        : 'Mulai Tracking';
  }

  Future<void> _handlePrimaryAction(OfflineTrackingState state) async {
    if (!_isOfflineMapUnlocked) {
      await _unlockOfflineMapWithLocation();
      return;
    }

    if (!state.isTracking && state.gpxRoutePoints.length < 2) {
      await _showUploadGpxRequiredDialog();
      return;
    }

    if (state.isTracking) {
      await _stopTracking();
      return;
    }

    await _startTracking();
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _greenActionButtonStyle() {
    const primaryGreen = Color(0xFF1B734A);
    return ElevatedButton.styleFrom(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      disabledBackgroundColor: Colors.grey.shade200,
      disabledForegroundColor: Colors.grey.shade700,
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Future<void> _showUploadGpxRequiredDialog() async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Upload GPX Diperlukan'),
          content: const Text(
            'Sebelum mulai tracking, upload GPX dulu dari tombol titik tiga (Aksi) lalu pilih Upload GPX.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Nanti'),
            ),
            ElevatedButton(
              style: _greenActionButtonStyle(),
              onPressed: () async {
                Navigator.of(context).pop();
                await _uploadGpx();
              },
              child: const Text('Upload Sekarang'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopSummaryCard(OfflineTrackingState state, Duration elapsed) {
    final gpsColor = _isOfflineMapUnlocked ? Colors.green : Colors.orange;
    final trackingColor = state.isTracking ? Colors.green : Colors.blueGrey;
    final cacheColor = _pendingCacheCount > 0 ? Colors.orange : Colors.green;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${heading.toStringAsFixed(0)}°',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.mountainName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.selectedGpxName == null
                            ? 'GPX belum dipilih'
                            : state.selectedGpxName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.blueGrey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusChip(
                  icon: _isOfflineMapUnlocked ? Icons.gps_fixed : Icons.gps_off,
                  label: _isOfflineMapUnlocked ? 'GPS siap' : 'GPS belum aktif',
                  color: gpsColor,
                ),
                _buildStatusChip(
                  icon: state.isTracking ? Icons.sensors : Icons.pause_circle,
                  label:
                      state.isTracking ? 'Tracking aktif' : 'Tracking nonaktif',
                  color: trackingColor,
                ),
                _buildStatusChip(
                  icon: Icons.cloud_upload,
                  label: _pendingCacheCount > 0
                      ? 'Cache $_pendingCacheCount'
                      : 'Cache bersih',
                  color: cacheColor,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Jarak: ${(state.trackedDistanceMeters / 1000).toStringAsFixed(2)} km',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text('Durasi: ${_formatDuration(elapsed)}'),
                const SizedBox(width: 8),
                Text('Titik: ${state.trackedPoints.length}'),
                const SizedBox(width: 8),
                Text('Pos: ${state.gpxWaypoints.length}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedMapOverlay() {
    return Container(
      color: Colors.white.withOpacity(0.9),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_off,
            size: 46,
            color: Colors.orange.shade700,
          ),
          const SizedBox(height: 12),
          const Text(
            'Aktifkan lokasi dulu sebelum mengakses offline map.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Setelah aktif, map bisa dipakai walau sinyal internet lemah. Track akan disimpan ke cache HP.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _isPreparingLocation
                ? null
                : () => _unlockOfflineMapWithLocation(),
            style: _greenActionButtonStyle(),
            icon: _isPreparingLocation
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey.shade700,
                    ),
                  )
                : const Icon(Icons.gps_fixed),
            label: const Text('Aktifkan Lokasi'),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(OfflineTrackingState state) {
    return Stack(
      children: [
        IgnorePointer(
          ignoring: !_isOfflineMapUnlocked,
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
              if (state.gpxRoutePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: state.gpxRoutePoints,
                      color: Colors.teal,
                      strokeWidth: 4,
                    ),
                  ],
                ),
              if (state.trackedPoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: state.trackedPoints,
                      color: Colors.blue,
                      strokeWidth: 4,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (state.currentPosition != null)
                    Marker(
                      point: LatLng(
                        state.currentPosition!.latitude,
                        state.currentPosition!.longitude,
                      ),
                      width: 44,
                      height: 44,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                  ...state.gpxWaypoints.map(
                    (waypoint) => Marker(
                      point: waypoint.point,
                      width: 40,
                      height: 40,
                      child: Tooltip(
                        message: waypoint.description == null ||
                                waypoint.description!.trim().isEmpty
                            ? waypoint.name
                            : '${waypoint.name}\n${waypoint.description}',
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.deepOrange,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  if (state.gpxRoutePoints.isNotEmpty)
                    Marker(
                      point: state.gpxRoutePoints.first,
                      width: 36,
                      height: 36,
                      child: const Icon(
                        Icons.play_circle_fill,
                        color: Colors.green,
                        size: 28,
                      ),
                    ),
                  if (state.gpxRoutePoints.length > 1)
                    Marker(
                      point: state.gpxRoutePoints.last,
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
        if (!_isOfflineMapUnlocked) _buildLockedMapOverlay(),
        Positioned(
          top: 12,
          right: 12,
          child: FloatingActionButton.small(
            heroTag: 'fit_map_button_offline_tracking',
            onPressed: _isOfflineMapUnlocked ? _fitMapToAllPoints : null,
            child: const Icon(
              Icons.center_focus_strong,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControlBar(OfflineTrackingState state) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isPreparingLocation
                    ? null
                    : () => _handlePrimaryAction(state),
                style: _greenActionButtonStyle(),
                icon: _isPreparingLocation
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.grey.shade700,
                        ),
                      )
                    : Icon(_primaryActionIcon(state)),
                label: Text(_primaryActionLabel(state)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _syncInfo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                ),
                if (_isSyncingCachedTracks)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<OfflineTrackingCubit, OfflineTrackingState>(
        builder: (context, state) {
          final elapsed = state.trackingStartedAt == null
              ? Duration.zero
              : DateTime.now().difference(state.trackingStartedAt!);

          return Scaffold(
            appBar: AppBar(
              title: const Text('Tracking Offline & Kompas'),
              actions: [
                PopupMenuButton<_OfflineMenuAction>(
                  tooltip: 'Aksi track',
                  onSelected: (value) {
                    unawaited(_onMenuActionSelected(value));
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<_OfflineMenuAction>(
                      value: _OfflineMenuAction.uploadGpx,
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.upload_file),
                        title: Text('Upload GPX'),
                      ),
                    ),
                    PopupMenuItem<_OfflineMenuAction>(
                      value: _OfflineMenuAction.fitMap,
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.center_focus_strong),
                        title: Text('Fit Peta'),
                      ),
                    ),
                    PopupMenuItem<_OfflineMenuAction>(
                      value: _OfflineMenuAction.exportTrack,
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.download),
                        title: Text('Simpan GPX'),
                      ),
                    ),
                    PopupMenuItem<_OfflineMenuAction>(
                      value: _OfflineMenuAction.syncCache,
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.cloud_sync),
                        title: Text('Sinkronkan Cache'),
                      ),
                    ),
                    PopupMenuItem<_OfflineMenuAction>(
                      value: _OfflineMenuAction.resetTrack,
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.restart_alt),
                        title: Text('Reset Track'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: _buildTopSummaryCard(state, elapsed),
                ),
                Expanded(
                  child: _buildMap(state),
                ),
              ],
            ),
            bottomNavigationBar: _buildBottomControlBar(state),
          );
        },
      ),
    );
  }
}
