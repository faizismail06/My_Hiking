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

  void setGpxData({required List<LatLng> points, String? fileName}) {
    emit(state.copyWith(
      gpxRoutePoints: List<LatLng>.from(points),
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
      trackingStartedAt: state.trackingStartedAt ?? DateTime.now(),
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
    emit(state.copyWith(isTracking: false));
  }

  void resetTracking() {
    emit(state.copyWith(
      trackedPoints: const [],
      trackedDistanceMeters: 0,
      clearTrackingStartedAt: true,
      clearCurrentPosition: true,
      isTracking: false,
    ));
  }
}
