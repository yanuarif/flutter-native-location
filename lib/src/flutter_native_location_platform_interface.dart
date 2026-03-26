import 'package:flutter_native_location/flutter_native_location.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_native_location_method_channel.dart';

abstract class FlutterNativeLocationPlatform extends PlatformInterface {
  FlutterNativeLocationPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterNativeLocationPlatform _instance =
      MethodChannelFlutterNativeLocation();

  /// Returns the default platform instance.
  static FlutterNativeLocationPlatform get instance => _instance;

  /// Allows platform-specific implementations to override the default instance.
  static set instance(FlutterNativeLocationPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Broadcast stream of [Position] emitted at each tracking interval.
  Stream<Position> get locationStream;

  /// Requests location permission and returns the status string.
  Future<String> requestPermission();

  /// Starts location tracking with the given [config].
  Future<void> startTracking(LocationConfig config);

  /// Pauses timer-based emission without stopping the underlying location manager.
  Future<void> pauseTracking();

  /// Resumes tracking after a pause.
  Future<void> resumeTracking();

  /// Stops tracking and releases native location resources.
  Future<void> stopTracking();

  /// Returns the current [TrackingState] from the native layer.
  Future<TrackingState> getTrackingState();

  /// Returns the last known [Position], or null if unavailable.
  Future<Position?> getLastLocation();

  /// Returns a freshly fetched [Position], or null if unavailable.
  Future<Position?> getCurrentLocation() {
    throw UnimplementedError('getCurrentLocation() has not been implemented.');
  }
}
