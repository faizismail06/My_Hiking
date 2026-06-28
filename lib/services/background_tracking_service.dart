import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_service.dart';

@pragma('vm:entry-point')
class BackgroundTrackingService {
  static const String activeTrackFileName = 'active_track.json';
  static const String _channelId = 'my_hiking_tracking_channel';
  static const String _channelName = 'MyHiking Tracking Lokasi';

  @pragma('vm:entry-point')
  static Future<void> initialize() async {
    // Explicitly create the notification channel BEFORE starting the service.
    // This is critical for MIUI/HyperOS devices that crash if the channel
    // doesn't exist when the foreground service posts its notification.
    //
    // IMPORTANT: Must call initialize() first, otherwise
    // resolvePlatformSpecificImplementation() returns null and the channel
    // is silently never created.
    final FlutterLocalNotificationsPlugin flnp = FlutterLocalNotificationsPlugin();
    await flnp.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    final androidPlugin = flnp.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Menampilkan status tracking lokasi di latar belakang',
          importance: Importance.low, // Low = no sound, still shows in notification bar
        ),
      );
    }

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _channelId,
        initialNotificationTitle: 'MyHiking Tracking',
        initialNotificationContent: 'Mempersiapkan lokasi...',
        foregroundServiceTypes: const [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) async {
      await service.stopSelf();
    });

    // Tracking state variables in background process
    int? orderId;
    String? mountainName;
    List<LatLng> trackedPoints = [];
    double trackedDistanceMeters = 0.0;
    int accumulatedDurationSeconds = 0;
    DateTime? trackingStartedAt;
    bool isTracking = false;
    String? selectedGpxName;
    List<LatLng> gpxRoutePoints = [];
    int lastCachedPointCount = 0;
    int lastSyncedPointCount = 0;

    StreamSubscription<Position>? positionSubscription;
    Timer? durationTimer;
    Timer? syncTimer;

    // Resolve file path helper
    Future<File> getActiveTrackFile() async {
      final baseDir = await getApplicationDocumentsDirectory();
      return File('${baseDir.path}/$activeTrackFileName');
    }

    // Save state to active_track.json
    Future<void> saveActiveTrack() async {
      try {
        final file = await getActiveTrackFile();
        final Map<String, dynamic> data = {
          'order_id': orderId,
          'mountain_name': mountainName,
          'tracked_points': trackedPoints.map((pt) => {'lat': pt.latitude, 'lng': pt.longitude}).toList(),
          'distance_meters': trackedDistanceMeters,
          'duration_seconds': accumulatedDurationSeconds,
          'started_at': trackingStartedAt?.toIso8601String(),
          'is_tracking': isTracking,
          'selected_gpx_name': selectedGpxName,
          'gpx_route_points': gpxRoutePoints.map((pt) => {'lat': pt.latitude, 'lng': pt.longitude}).toList(),
        };
        await file.writeAsString(jsonEncode(data), flush: true);
      } catch (e) {
        debugPrint('Error saving active track in background: $e');
      }
    }

    // Load active track helper
    Future<void> loadActiveTrack() async {
      try {
        final file = await getActiveTrackFile();
        if (await file.exists()) {
          final raw = await file.readAsString();
          if (raw.trim().isNotEmpty) {
            final data = jsonDecode(raw);
            orderId = data['order_id'];
            mountainName = data['mountain_name'];
            trackedDistanceMeters = (data['distance_meters'] ?? 0.0).toDouble();
            accumulatedDurationSeconds = data['duration_seconds'] ?? 0;
            isTracking = data['is_tracking'] ?? false;
            selectedGpxName = data['selected_gpx_name'];
            
            if (data['started_at'] != null) {
              trackingStartedAt = DateTime.parse(data['started_at']);
            }

            final List? pts = data['tracked_points'];
            if (pts != null) {
              trackedPoints = pts.map((item) => LatLng(item['lat'], item['lng'])).toList();
            }

            final List? routePts = data['gpx_route_points'];
            if (routePts != null) {
              gpxRoutePoints = routePts.map((item) => LatLng(item['lat'], item['lng'])).toList();
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading active track in background: $e');
      }
    }

    // GPX XML string generator
    String buildTrackedGpx() {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final buffer = StringBuffer();
      buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
      buffer.writeln('<gpx version="1.1" creator="MyHiking Offline Tracker" xmlns="http://www.topografix.com/GPX/1/1">');
      buffer.writeln('  <metadata>');
      buffer.writeln('    <name>${orderId != null ? 'Track $orderId' : 'Track'}</name>');
      buffer.writeln('    <time>$nowIso</time>');
      buffer.writeln('  </metadata>');
      buffer.writeln('  <trk>');
      buffer.writeln('    <name>Track ${orderId ?? ''}</name>');
      buffer.writeln('    <trkseg>');
      for (final point in trackedPoints) {
        buffer.writeln('      <trkpt lat="${point.latitude}" lon="${point.longitude}" />');
      }
      buffer.writeln('    </trkseg>');
      buffer.writeln('  </trk>');
      buffer.writeln('</gpx>');
      return buffer.toString();
    }

    // Internet connectivity check helper
    Future<bool> hasInternetConnection() async {
      try {
        final lookup = await InternetAddress.lookup('example.com').timeout(
          const Duration(seconds: 3),
        );
        return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }

    // Resolve pending cache queue file
    Future<File> getPendingQueueFile() async {
      final baseDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${baseDir.path}/offline_tracking_cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      return File('${cacheDir.path}/pending_tracks.json');
    }

    // Read pending queue
    Future<List<Map<String, dynamic>>> readPendingQueue() async {
      try {
        final file = await getPendingQueueFile();
        if (!await file.exists()) {
          return [];
        }
        final raw = await file.readAsString();
        if (raw.trim().isEmpty) {
          return [];
        }
        final decoded = jsonDecode(raw);
        if (decoded is! List) {
          return [];
        }
        return decoded
            .whereType<Map>()
            .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
            .toList();
      } catch (_) {
        return [];
      }
    }

    // Write pending queue
    Future<void> writePendingQueue(List<Map<String, dynamic>> queue) async {
      try {
        final file = await getPendingQueueFile();
        await file.writeAsString(jsonEncode(queue), flush: true);
      } catch (e) {
        debugPrint('Error writing pending queue: $e');
      }
    }

    // Send cache item to server helper
    Future<void> sendCacheItemToServer(Map<String, dynamic> item, String token) async {
      final clientCacheId = item['client_cache_id'] ?? item['cache_id'] ?? '${orderId}_bg_${DateTime.now().millisecondsSinceEpoch}';
      final itemOrderId = item['order_id'] ?? orderId;
      final url = Uri.parse('$baseUrl/orders/$itemOrderId/offline-track-sync');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'client_cache_id': clientCacheId,
          'source': 'mobile_background_tracking',
          'cached_at': item['cached_at'],
          'point_count': item['point_count'],
          'distance_meters': item['distance_meters'],
          'duration_seconds': item['duration_seconds'],
          'gpx_content': item['gpx_content'],
        }),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 409) {
        final decoded = jsonDecode(response.body);
        if (decoded['code'] == 'ORDER_STATUS_NOT_SYNCABLE') {
          throw OrderNotSyncableException();
        }
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      final trimmedBody = response.body.trim();
      if (trimmedBody.isEmpty) {
        throw Exception('Sync response kosong.');
      }

      final decoded = jsonDecode(trimmedBody);
      final success = decoded['success'] == true;
      final data = decoded['data'];
      if (!success || data is! Map) {
        throw Exception('Sync response tidak sukses.');
      }

      final syncId = data['sync_id'];
      final syncStatus = data['sync_status']?.toString().toLowerCase();
      final acceptedStatus = syncStatus == 'synced' || syncStatus == 'duplicate';

      if (syncId == null || !acceptedStatus) {
        throw Exception('Sync status belum valid.');
      }
    }

    // Stop and cleanup service on force checkout
    void forceCheckoutFlow() async {
      await positionSubscription?.cancel();
      durationTimer?.cancel();
      syncTimer?.cancel();
      
      positionSubscription = null;
      durationTimer = null;
      syncTimer = null;

      isTracking = false;
      
      // Delete active track
      try {
        final file = await getActiveTrackFile();
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}

      // Delete all caches for this order
      try {
        final queue = await readPendingQueue();
        queue.removeWhere((item) => item['order_id'] == orderId);
        await writePendingQueue(queue);
      } catch (_) {}

      service.invoke('forceCheckout', {
        'order_id': orderId,
        'message': 'Pendaki telah checkout. Tracking dihentikan dan cache lokal dibersihkan.'
      });

      await service.stopSelf();
    }

    // Process periodic synchronization and caching
    Future<void> processSyncCycle() async {
      if (orderId == null || !isTracking) return;

      try {
        final isOnline = await hasInternetConnection();
        if (isOnline) {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');
          if (token == null || token.isEmpty) return;

          // 1. Sync pending cache if exists
          final queue = await readPendingQueue();
          if (queue.isNotEmpty) {
            final remaining = <Map<String, dynamic>>[];
            for (var item in queue) {
              try {
                await sendCacheItemToServer(item, token);
              } on OrderNotSyncableException {
                if (item['order_id'] == orderId) {
                  rethrow;
                }
                continue; // drop other order items
              } catch (e) {
                final err = e.toString().toLowerCase();
                if (err.contains('gpx_too_large') || err.contains('http 413') || err.contains('order_status_not_syncable')) {
                  continue; // drop this item
                }
                remaining.add(item);
              }
            }
            await writePendingQueue(remaining);
            service.invoke('cacheUpdate', {
              'count': remaining.length,
              'info': remaining.isEmpty ? 'Sinkron selesai. Semua cache terkirim.' : 'Sebagian data belum terkirim (${remaining.length} antrean).',
            });
          }

          // 2. Sync the latest track real-time if there is a location change since the last sync
          if (trackedPoints.isNotEmpty && trackedPoints.length > lastSyncedPointCount) {
            final clientCacheId = '${orderId}_realtime_${DateTime.now().millisecondsSinceEpoch}';
            await sendCacheItemToServer({
              'order_id': orderId,
              'client_cache_id': clientCacheId,
              'cached_at': DateTime.now().toIso8601String(),
              'point_count': trackedPoints.length,
              'distance_meters': trackedDistanceMeters,
              'duration_seconds': accumulatedDurationSeconds,
              'gpx_content': buildTrackedGpx(),
            }, token);

            lastSyncedPointCount = trackedPoints.length;
            lastCachedPointCount = trackedPoints.length;

            final queue = await readPendingQueue();
            service.invoke('cacheUpdate', {
              'count': queue.length,
              'info': 'Lokasi disinkronkan real-time.',
            });
          }
        } else {
          // OFFLINE: Cache current track if we have at least 1 point and it changed since last cache
          if (trackedPoints.isNotEmpty && trackedPoints.length > lastCachedPointCount) {
            final queue = await readPendingQueue();
            
            final clientCacheId = '${orderId}_${DateTime.now().millisecondsSinceEpoch}';
            queue.add({
              'cache_id': clientCacheId,
              'order_id': orderId,
              'mountain_name': mountainName,
              'cached_at': DateTime.now().toIso8601String(),
              'point_count': trackedPoints.length,
              'distance_meters': trackedDistanceMeters,
              'duration_seconds': accumulatedDurationSeconds,
              'gpx_content': buildTrackedGpx(),
            });
            await writePendingQueue(queue);

            lastCachedPointCount = trackedPoints.length;

            service.invoke('cacheUpdate', {
              'count': queue.length,
              'info': 'Koneksi offline. Track disimpan ke cache lokal (${queue.length} antrean).',
            });
          }
        }
      } on OrderNotSyncableException {
        forceCheckoutFlow();
      } catch (e) {
        debugPrint('Sync cycle exception: $e');
      }
    }

    // Format HH:MM:SS helper
    String formatDuration(int seconds) {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      final secs = seconds % 60;
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }

    // Update Notification Content
    void updateNotification() {
      if (service is AndroidServiceInstance) {
        final distanceKm = (trackedDistanceMeters / 1000).toStringAsFixed(2);
        final elapsedStr = formatDuration(accumulatedDurationSeconds);
        
        service.setForegroundNotificationInfo(
          title: 'MyHiking: Tracking Offline Aktif',
          content: 'Gunung: $mountainName | Jarak: $distanceKm km | Waktu: $elapsedStr',
        );
      }
    }

    // Start location and timer listeners
    void startTrackingFlow() async {
      // Cancel previous streams/timers synchronously to prevent race conditions
      if (positionSubscription != null) {
        positionSubscription!.cancel();
        positionSubscription = null;
      }
      if (durationTimer != null) {
        durationTimer!.cancel();
        durationTimer = null;
      }
      if (syncTimer != null) {
        syncTimer!.cancel();
        syncTimer = null;
      }

      trackingStartedAt = DateTime.now();
      isTracking = true;

      // GPS Position Listener
      positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 5,
        ),
      ).listen((Position position) async {
        final nextPoint = LatLng(position.latitude, position.longitude);
        double addedDistance = 0.0;

        if (trackedPoints.isNotEmpty) {
          final previousPoint = trackedPoints.last;
          addedDistance = const Distance().as(LengthUnit.Meter, previousPoint, nextPoint);
        }

        // Avoid adding points if user is static
        if (trackedPoints.isEmpty || addedDistance > 1.5) {
          trackedPoints.add(nextPoint);
          trackedDistanceMeters += addedDistance;

          await saveActiveTrack();
          updateNotification();

          // Invoke update to foreground UI listeners
          service.invoke('update', {
            'lat': position.latitude,
            'lng': position.longitude,
            'distance': trackedDistanceMeters,
            'duration': accumulatedDurationSeconds,
            'points': trackedPoints.map((pt) => {'lat': pt.latitude, 'lng': pt.longitude}).toList(),
            'current_position': {
              'lat': position.latitude,
              'lng': position.longitude,
              'altitude': position.altitude,
              'heading': position.heading,
              'speed': position.speed,
              'accuracy': position.accuracy,
            }
          });
        }
      }, onError: (err) {
        debugPrint('Geolocator stream error in background: $err');
      });

      // Duration Incrementor Timer (every 1 second)
      durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        accumulatedDurationSeconds++;
        updateNotification();
        
        // Save duration changes to local json file periodically to survive crash/reboot
        if (accumulatedDurationSeconds % 10 == 0) {
          await saveActiveTrack();
        }

        // Invoke update to UI
        service.invoke('durationUpdate', {
          'duration': accumulatedDurationSeconds,
        });
      });

      // Auto-Sync & Cache Periodik setiap 10 detik
      syncTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        processSyncCycle();
      });

      updateNotification();

      // Perform file save asynchronously at the end
      await saveActiveTrack();
    }

    // Stop location tracking
    void stopTrackingFlow() async {
      await positionSubscription?.cancel();
      durationTimer?.cancel();
      syncTimer?.cancel();
      
      positionSubscription = null;
      durationTimer = null;
      syncTimer = null;

      isTracking = false;
      await saveActiveTrack();
      
      await service.stopSelf();
    }

    // Listen to UI initialization events
    service.on('start').listen((event) async {
      orderId = event?['order_id'];
      mountainName = event?['mountain_name'];
      selectedGpxName = event?['selected_gpx_name'];

      final List? routePoints = event?['gpx_route_points'];
      if (routePoints != null) {
        gpxRoutePoints = routePoints.map((item) => LatLng(item['lat'], item['lng'])).toList();
      }

      trackedPoints = [];
      trackedDistanceMeters = 0.0;
      accumulatedDurationSeconds = 0;

      startTrackingFlow();
    });

    service.on('stop').listen((event) async {
      stopTrackingFlow();
    });

    // Check current state or restore from file
    await loadActiveTrack();
    if (isTracking) {
      startTrackingFlow();
    }
  }
}

class OrderNotSyncableException implements Exception {
  final String message;
  OrderNotSyncableException([this.message = "Order status is no longer syncable (checkout detected)."]);
  @override
  String toString() => message;
}
