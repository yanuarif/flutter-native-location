import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_location/src/enums/tracking_state.dart';
import 'package:flutter_native_location/src/models/location_config.dart';
import 'package:flutter_native_location/src/models/position.dart';

import 'flutter_native_location_platform_interface.dart';

class MethodChannelFlutterNativeLocation extends FlutterNativeLocationPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_native_location/methods');

  @visibleForTesting
  final eventChannel = const EventChannel(
    'flutter_native_location/location_stream',
  );

  /// Broadcast stream of [Position] received from the native event channel.
  @override
  Stream<Position> get locationStream {
    return eventChannel.receiveBroadcastStream().map(
      (event) => Position.fromJson(Map<String, dynamic>.from(event as Map)),
    );
  }

  /// Invokes `requestPermission` on the native layer and returns the permission status string.
  @override
  Future<String> requestPermission() async {
    final result = await methodChannel.invokeMethod<String>(
      'requestPermission',
    );
    return result ?? 'notDetermined';
  }

  /// Invokes `startTracking` on the native layer with the given config parameters.
  @override
  Future<void> startTracking(LocationConfig config) async {
    try {
      await methodChannel.invokeMethod('startTracking', {
        'intervalSeconds': config.intervalSeconds,
        'accuracyFilter': config.resolvedAccuracyFilter,
        'accuracyLevel': config.accuracy.name,
      });
    } catch (e) {
      throw PlatformException(
        code: 'START_TRACKING_FAILED',
        message: 'Failed to start tracking',
        details: e,
      );
    }
  }

  /// Invokes `pauseTracking` on the native layer.
  @override
  Future<void> pauseTracking() async {
    try {
      await methodChannel.invokeMethod('pauseTracking');
    } catch (e) {
      throw PlatformException(
        code: 'PAUSE_TRACKING_FAILED',
        message: 'Failed to pause tracking',
        details: e,
      );
    }
  }

  /// Invokes `resumeTracking` on the native layer.
  @override
  Future<void> resumeTracking() async {
    try {
      await methodChannel.invokeMethod('resumeTracking');
    } catch (e) {
      throw PlatformException(
        code: 'RESUME_TRACKING_FAILED',
        message: 'Failed to resume tracking',
        details: e,
      );
    }
  }

  /// Invokes `stopTracking` on the native layer.
  @override
  Future<void> stopTracking() async {
    try {
      await methodChannel.invokeMethod('stopTracking');
    } catch (e) {
      throw PlatformException(
        code: 'STOP_TRACKING_FAILED',
        message: 'Failed to stop tracking',
        details: e,
      );
    }
  }

  /// Fetches the current tracking state string from native and maps it to [TrackingState].
  @override
  Future<TrackingState> getTrackingState() async {
    final raw = await methodChannel.invokeMethod<String>('getTrackingState');
    return switch (raw) {
      'tracking' => TrackingState.tracking,
      'paused' => TrackingState.paused,
      'error' => TrackingState.error,
      _ => TrackingState.idle,
    };
  }

  /// Fetches the last known location from native and deserialises it into a [Position].
  @override
  Future<Position?> getLastLocation() async {
    try {
      final raw = await methodChannel.invokeMethod<Map>('getLastLocation');
      if (raw == null) return null;
      return Position.fromJson(Map<String, dynamic>.from(raw));
    } catch (e) {
      throw PlatformException(
        code: 'GET_LAST_LOCATION_FAILED',
        message: 'Failed to get last location',
        details: e,
      );
    }
  }

  /// Fetches a freshly fetched location from native and deserialises it into a [Position].
  @override
  Future<Position?> getCurrentLocation() async {
    try {
      final raw = await methodChannel.invokeMethod<Map>('getCurrentLocation');
      if (raw == null) return null;
      return Position.fromJson(Map<String, dynamic>.from(raw));
    } catch (e) {
      throw PlatformException(
        code: 'GET_CURRENT_LOCATION_FAILED',
        message: 'Failed to get current location',
        details: e,
      );
    }
  }
}
