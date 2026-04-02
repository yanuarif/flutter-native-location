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

  // ── Ref-counted singleton tracking session ────────────────────────────────

  static StreamController<Position>? _sharedController;
  static StreamSubscription<dynamic>? _nativeEventSub;
  static int _subscriberCount = 0;

  /// Returns a stream of [Position] updates.
  ///
  /// - First subscriber starts native tracking (config applied once).
  /// - Subsequent subscribers share the same tracking session.
  /// - When all subscribers cancel, native tracking stops automatically.
  @override
  Stream<Position> getLocationStream(LocationConfig config) {
    late StreamController<Position> outerController;
    StreamSubscription<Position>? innerSub;

    outerController = StreamController<Position>(
      onListen: () {
        _subscriberCount++;

        if (_subscriberCount == 1) {
          // First subscriber: create shared broadcast controller and wire
          // the EventChannel (which triggers native onListen → startTracking).
          _sharedController = StreamController<Position>.broadcast();
          _nativeEventSub = eventChannel
              .receiveBroadcastStream({'accuracyLevel': config.accuracy.name})
              .listen(
                (event) {
                  try {
                    final pos = Position.fromJson(
                      Map<String, dynamic>.from(event as Map),
                    );
                    _sharedController?.add(pos);
                  } catch (e, st) {
                    _sharedController?.addError(e, st);
                  }
                },
                onError: (Object err, StackTrace st) =>
                    _sharedController?.addError(err, st),
              );
        }

        // Forward shared events to this individual subscriber.
        innerSub = _sharedController!.stream.listen(
          (pos) {
            if (!outerController.isClosed) outerController.add(pos);
          },
          onError: (Object err, StackTrace st) {
            if (!outerController.isClosed) outerController.addError(err, st);
          },
        );
      },
      onCancel: () async {
        await innerSub?.cancel();
        innerSub = null;
        _subscriberCount--;

        if (_subscriberCount == 0) {
          // Last subscriber gone: cancel EventChannel (triggers native onCancel
          // → stopTracking) and tear down the shared controller.
          await _nativeEventSub?.cancel();
          _nativeEventSub = null;
          _sharedController = null;
        }
      },
    );

    return outerController.stream;
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
