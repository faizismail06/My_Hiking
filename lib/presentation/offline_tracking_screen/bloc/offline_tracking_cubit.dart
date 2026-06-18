import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'offline_tracking_state.dart';

class OfflineTrackingCubit extends Cubit<OfflineTrackingState> {
  OfflineTrackingCubit() : super(const OfflineTrackingState());

  void setCurrentPosition(Position position) {
    emit(state.copyWith(currentPosition: position));
  }

  void setUploading(bool value) {
    emit(state.copyWith(isUploadingGpx: value));
  }

  void restoreTrackingState({
    required List<LatLng> trackedPoints,
    required double distanceMeters,
    required Duration duration,
    required bool isTracking,
    DateTime? startedAt,
    String? gpxName,
    List<LatLng>? gpxRoutePoints,
  }) {
    emit(state.copyWith(
      trackedPoints: List<LatLng>.from(trackedPoints),
      trackedDistanceMeters: distanceMeters,
      accumulatedDuration: duration,
      isTracking: isTracking,
      trackingStartedAt: startedAt,
      selectedGpxName: gpxName,
      gpxRoutePoints: gpxRoutePoints != null ? List<LatLng>.from(gpxRoutePoints) : null,
    ));
  }

  void updateTrackingMetrics({
    required List<LatLng> trackedPoints,
    required double distanceMeters,
    required Duration duration,
    Position? currentPosition,
  }) {
    emit(state.copyWith(
      trackedPoints: List<LatLng>.from(trackedPoints),
      trackedDistanceMeters: distanceMeters,
      accumulatedDuration: duration,
      currentPosition: currentPosition,
    ));
  }

  void updateDuration(Duration duration) {
    emit(state.copyWith(
      accumulatedDuration: duration,
    ));
  }

  void setGpxData({
    required List<LatLng> points,
    List<OfflineGpxWaypoint>? waypoints,
    String? fileName,
  }) {
    emit(state.copyWith(
      gpxRoutePoints: List<LatLng>.from(points),
      gpxWaypoints: List<OfflineGpxWaypoint>.from(waypoints ?? const []),
      selectedGpxName: fileName,
    ));
  }

  void startTracking({required Position current, required LatLng firstPoint}) {
    final nextTracked = state.trackedPoints.isEmpty
        ? <LatLng>[firstPoint]
        : List<LatLng>.from(state.trackedPoints);

    emit(state.copyWith(
      currentPosition: current,
      isTracking: true,
      trackingStartedAt: DateTime.now(),
      clearTrackingStoppedAt: true,
      trackedPoints: nextTracked,
    ));
  }

  void appendTrackedPoint({
    required Position position,
    required LatLng point,
    required double addedDistanceMeters,
  }) {
    final nextTracked = List<LatLng>.from(state.trackedPoints)..add(point);
    emit(state.copyWith(
      currentPosition: position,
      trackedPoints: nextTracked,
      trackedDistanceMeters: state.trackedDistanceMeters + addedDistanceMeters,
    ));
  }

  void stopTracking() {
    final now = DateTime.now();
    final segmentDuration = state.trackingStartedAt == null
        ? Duration.zero
        : now.difference(state.trackingStartedAt!);

    emit(state.copyWith(
      isTracking: false,
      trackingStoppedAt: now,
      accumulatedDuration: state.accumulatedDuration + segmentDuration,
      clearTrackingStartedAt: true,
    ));
  }

  void resetTracking() {
    emit(state.copyWith(
      trackedPoints: const [],
      trackedDistanceMeters: 0,
      accumulatedDuration: Duration.zero,
      clearTrackingStartedAt: true,
      clearTrackingStoppedAt: true,
      clearCurrentPosition: true,
      isTracking: false,
    ));
  }
}
