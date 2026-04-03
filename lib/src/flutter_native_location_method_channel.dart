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

  // Latest raw event buffered from the native stream for periodic sampling.
  Map<String, dynamic>? _latestRawEvent;

  /// Returns a stream of [Position] updates.
  ///
  /// - First subscriber starts native tracking (config applied once).
  /// - Subsequent subscribers share the same tracking session.
  /// - When all subscribers cancel, native tracking stops automatically.
  ///
  /// If [LocationConfig.timeLimit] is set, the stream acts as a **periodic
  /// sampler**: the native GPS runs freely and the latest fix is emitted on
  /// a fixed clock tick every [timeLimit] duration, giving a stable cadence
  /// regardless of how often the hardware delivers updates.
  @override
  Stream<Position> getLocationStream(LocationConfig config) {
    if (_positionStream != null) {
      return _positionStream!;
    }

    final rawBroadcast = eventChannel.receiveBroadcastStream({
      'accuracyLevel': config.accuracy.name,
    }).asBroadcastStream(
      onCancel: (subscription) {
        subscription.cancel();
        _positionStream = null;
        _latestRawEvent = null;
      },
    );

    Stream<Position> outputStream;

    if (config.timeLimit != null) {
      // --- Periodic sampler ---
      // Native GPS fires at its own cadence. We buffer every incoming fix and
      // re-emit the latest one on a fixed Timer tick. This decouples the
      // emission cadence from GPS hardware timing, giving a stable N-second
      // interval whether the screen is on or off.
      final controller = StreamController<Position>.broadcast();

      // Sink native events into the buffer; forward errors as-is.
      final rawSub = rawBroadcast.listen(
        (event) {
          _latestRawEvent = Map<String, dynamic>.from(event as Map);
        },
        onError: controller.addError,
        onDone: controller.close,
      );

      // Emit the latest buffered fix on every tick.
      final timer = Timer.periodic(config.timeLimit!, (_) {
        final latest = _latestRawEvent;
        if (latest != null && !controller.isClosed) {
          controller.add(Position.fromJson(latest));
        }
      });

      // Clean up when all subscribers leave.
      controller.onCancel = () {
        timer.cancel();
        rawSub.cancel();
        _positionStream = null;
        _latestRawEvent = null;
      };

      outputStream = controller.stream;
    } else {
      // --- Pass-through (no interval) ---
      // Forward every native event directly.
      outputStream = rawBroadcast.map<Position>(
        (dynamic event) =>
            Position.fromJson(Map<String, dynamic>.from(event as Map)),
      );
    }

    _positionStream = outputStream;

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
