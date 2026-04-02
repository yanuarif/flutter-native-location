import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  Stream<Position>? _positionStream;

  /// Returns a stream of [Position] updates.
  ///
  /// - First subscriber starts native tracking (config applied once).
  /// - Subsequent subscribers share the same tracking session.
  /// - When all subscribers cancel, native tracking stops automatically.
  @override
  Stream<Position> getLocationStream(LocationConfig config) {
    if (_positionStream != null) {
      return _positionStream!;
    }

    final originalStream = eventChannel.receiveBroadcastStream({
      'accuracyLevel': config.accuracy.name,
    });

    var positionStream = originalStream.asBroadcastStream(
      onCancel: (subscription) {
        subscription.cancel();
        _positionStream = null;
      },
    );

    if (config.timeLimit != null) {
      positionStream = positionStream.timeout(
        config.timeLimit!,
        onTimeout: (sink) {
          _positionStream = null;
          sink.addError(
            TimeoutException(
              'Time limit reached while waiting for position update.',
              config.timeLimit,
            ),
          );
          sink.close();
        },
      );
    }

    _positionStream = positionStream.map<Position>((dynamic event) {
      return Position.fromJson(Map<String, dynamic>.from(event as Map));
    });

    return _positionStream!;
  }

  /// Fetches the last known location from native.
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

  /// Fetches a fresh location from native.
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
