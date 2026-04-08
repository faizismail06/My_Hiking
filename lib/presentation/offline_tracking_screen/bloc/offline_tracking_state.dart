import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class OfflineTrackingState {
  final List<LatLng> gpxRoutePoints;
  final List<LatLng> trackedPoints;
  final Position? currentPosition;
  final bool isUploadingGpx;
  final bool isTracking;
  final double trackedDistanceMeters;
  final DateTime? trackingStartedAt;
  final String? selectedGpxName;

  const OfflineTrackingState({
    this.gpxRoutePoints = const [],
    this.trackedPoints = const [],
    this.currentPosition,
    this.isUploadingGpx = false,
    this.isTracking = false,
    this.trackedDistanceMeters = 0,
    this.trackingStartedAt,
    this.selectedGpxName,
  });

  OfflineTrackingState copyWith({
    List<LatLng>? gpxRoutePoints,
    List<LatLng>? trackedPoints,
    Position? currentPosition,
    bool clearCurrentPosition = false,
    bool? isUploadingGpx,
    bool? isTracking,
    double? trackedDistanceMeters,
    DateTime? trackingStartedAt,
    bool clearTrackingStartedAt = false,
    String? selectedGpxName,
    bool clearSelectedGpxName = false,
  }) {
    return OfflineTrackingState(
      gpxRoutePoints: gpxRoutePoints ?? this.gpxRoutePoints,
      trackedPoints: trackedPoints ?? this.trackedPoints,
      currentPosition: clearCurrentPosition
          ? null
          : (currentPosition ?? this.currentPosition),
      isUploadingGpx: isUploadingGpx ?? this.isUploadingGpx,
      isTracking: isTracking ?? this.isTracking,
      trackedDistanceMeters: trackedDistanceMeters ?? this.trackedDistanceMeters,
      trackingStartedAt: clearTrackingStartedAt
          ? null
          : (trackingStartedAt ?? this.trackingStartedAt),
      selectedGpxName: clearSelectedGpxName
          ? null
          : (selectedGpxName ?? this.selectedGpxName),
    );
  }
}
