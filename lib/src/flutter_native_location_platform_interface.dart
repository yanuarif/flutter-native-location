import 'package:flutter_native_location/src/models/location_config.dart';
import 'package:flutter_native_location/src/models/position.dart';
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

  /// Returns a broadcast [Stream<Position>]. Tracking starts on first subscribe
  /// and stops automatically when all subscriptions are cancelled.
  Stream<Position> getLocationStream(LocationConfig config);

  /// Returns the last known [Position], or null if unavailable.
  Future<Position?> getLastLocation();

  /// Returns a freshly fetched [Position], or null if unavailable.
  Future<Position?> getCurrentLocation() {
    throw UnimplementedError('getCurrentLocation() has not been implemented.');
  }
}
