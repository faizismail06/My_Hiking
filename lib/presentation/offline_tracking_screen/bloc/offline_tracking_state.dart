import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class OfflineGpxWaypoint {
  final LatLng point;
  final String name;
  final String? description;

  const OfflineGpxWaypoint({
    required this.point,
    required this.name,
    this.description,
  });
}

class OfflineTrackingState {
  final List<LatLng> gpxRoutePoints;
  final List<OfflineGpxWaypoint> gpxWaypoints;
  final List<LatLng> trackedPoints;
  final Position? currentPosition;
  final bool isUploadingGpx;
  final bool isTracking;
  final double trackedDistanceMeters;
  final Duration accumulatedDuration;
  final DateTime? trackingStartedAt;
  final DateTime? trackingStoppedAt;
  final String? selectedGpxName;

  const OfflineTrackingState({
    this.gpxRoutePoints = const [],
    this.gpxWaypoints = const [],
    this.trackedPoints = const [],
    this.currentPosition,
    this.isUploadingGpx = false,
    this.isTracking = false,
    this.trackedDistanceMeters = 0,
    this.accumulatedDuration = Duration.zero,
    this.trackingStartedAt,
    this.trackingStoppedAt,
    this.selectedGpxName,
  });

  Duration get elapsedDuration {
    if (trackingStartedAt == null) {
      return accumulatedDuration;
    }
    if (isTracking) {
      return accumulatedDuration + DateTime.now().difference(trackingStartedAt!);
    }
    return accumulatedDuration;
  }

  OfflineTrackingState copyWith({
    List<LatLng>? gpxRoutePoints,
    List<OfflineGpxWaypoint>? gpxWaypoints,
    List<LatLng>? trackedPoints,
    Position? currentPosition,
    bool clearCurrentPosition = false,
    bool? isUploadingGpx,
    bool? isTracking,
    double? trackedDistanceMeters,
    Duration? accumulatedDuration,
    DateTime? trackingStartedAt,
    bool clearTrackingStartedAt = false,
    DateTime? trackingStoppedAt,
    bool clearTrackingStoppedAt = false,
    String? selectedGpxName,
    bool clearSelectedGpxName = false,
  }) {
    return OfflineTrackingState(
      gpxRoutePoints: gpxRoutePoints ?? this.gpxRoutePoints,
      gpxWaypoints: gpxWaypoints ?? this.gpxWaypoints,
      trackedPoints: trackedPoints ?? this.trackedPoints,
      currentPosition: clearCurrentPosition
          ? null
          : (currentPosition ?? this.currentPosition),
      isUploadingGpx: isUploadingGpx ?? this.isUploadingGpx,
      isTracking: isTracking ?? this.isTracking,
      trackedDistanceMeters:
          trackedDistanceMeters ?? this.trackedDistanceMeters,
      accumulatedDuration: accumulatedDuration ?? this.accumulatedDuration,
      trackingStartedAt: clearTrackingStartedAt
          ? null
          : (trackingStartedAt ?? this.trackingStartedAt),
      trackingStoppedAt: clearTrackingStoppedAt
          ? null
          : (trackingStoppedAt ?? this.trackingStoppedAt),
      selectedGpxName: clearSelectedGpxName
          ? null
          : (selectedGpxName ?? this.selectedGpxName),
    );
  }
}
