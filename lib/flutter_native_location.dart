import 'dart:async';
import 'package:flutter_native_location/src/flutter_native_location_platform_interface.dart';
import 'src/enums/_enums.dart';
import 'src/models/_models.dart';

export 'src/enums/_enums.dart';
export 'src/models/_models.dart';

class FlutterNativeLocation {
  FlutterNativeLocation._();

  static FlutterNativeLocation? _instance;

  /// Returns the singleton instance. Throws [StateError] if [init] has not been called.
  static FlutterNativeLocation get instance {
    if (_instance == null) {
      throw StateError(
        'FlutterNativeLocation is not initialised. '
        'Call FlutterNativeLocation.init(config) before accessing instance.',
      );
    }
    return _instance!;
  }

  /// Returns true if [init] has already been called.
  static bool get isInitialised => _instance != null;

  late LocationConfig _config;
  TrackingState _state = TrackingState.idle;

  /// Returns the config used to initialise this instance.
  LocationConfig get config => _config;

  /// Returns the locally-cached tracking state. Call [getTrackingState] for the authoritative native value.
  TrackingState get state => _state;

  /// Initialises the plugin with [config], requests location permission, and optionally starts tracking.
  ///
  /// Calling [init] a second time replaces the previous config; tracking is restarted if active.
  static Future<FlutterNativeLocation> init(LocationConfig config) async {
    _instance ??= FlutterNativeLocation._();
    await _instance!._setup(config);
    return _instance!;
  }

  Future<void> _setup(LocationConfig config) async {
    final wasTracking = _state == TrackingState.tracking;
    if (wasTracking) await stopTracking();
    _config = config;
    final permission = await requestPermission();
    final granted =
        permission == 'authorizedAlways' || permission == 'authorizedWhenInUse';
    if (config.autoStart && granted) {
      await startTracking();
    }
  }

  /// Broadcast stream of [Position] emitted every [LocationConfig.intervalSeconds] seconds.
  ///
  /// Cancelling the subscription does NOT stop tracking — call [stopTracking] explicitly.
  Stream<Position> get locationStream {
    return FlutterNativeLocationPlatform.instance.locationStream;
  }

  /// Requests location permission. Returns one of: `authorizedAlways`, `authorizedWhenInUse`, `denied`, `notDetermined`.
  Future<String> requestPermission() {
    return FlutterNativeLocationPlatform.instance.requestPermission();
  }

  /// Starts location tracking using [config], or [configOverride] if provided.
  Future<void> startTracking({LocationConfig? configOverride}) async {
    final effective = configOverride ?? _config;
    await FlutterNativeLocationPlatform.instance.startTracking(effective);
    _state = TrackingState.tracking;
  }

  /// Pauses timer-based emission without stopping the underlying location manager.
  Future<void> pauseTracking() async {
    await FlutterNativeLocationPlatform.instance.pauseTracking();
    _state = TrackingState.paused;
  }

  /// Resumes tracking after a pause.
  Future<void> resumeTracking() async {
    await FlutterNativeLocationPlatform.instance.resumeTracking();
    _state = TrackingState.tracking;
  }

  /// Stops tracking and releases native location resources.
  Future<void> stopTracking() async {
    await FlutterNativeLocationPlatform.instance.stopTracking();
    _state = TrackingState.idle;
  }

  /// Fetches the authoritative [TrackingState] from the native layer and updates the local cache.
  Future<TrackingState> getTrackingState() async {
    _state = await FlutterNativeLocationPlatform.instance.getTrackingState();
    return _state;
  }

  /// Returns the last known [Position], or null if unavailable.
  Future<Position?> getLastLocation() async {
    return await FlutterNativeLocationPlatform.instance.getLastLocation();
  }

  /// Replaces the current config. If [restartTracking] is true and tracking is active, restarts automatically.
  Future<void> reconfigure(
    LocationConfig newConfig, {
    bool restartTracking = true,
  }) async {
    final wasTracking = _state == TrackingState.tracking;
    if (wasTracking && restartTracking) await stopTracking();
    _config = newConfig;
    if (wasTracking && restartTracking) await startTracking();
  }
}
