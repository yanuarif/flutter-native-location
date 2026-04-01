import 'dart:async';

import 'package:flutter_native_location/src/flutter_native_location_platform_interface.dart';
import 'src/models/_models.dart';

export 'src/enums/_enums.dart';
export 'src/models/_models.dart';

class FlutterNativeLocation {
  FlutterNativeLocation._();

  /// Returns a [Stream<Position>] that starts native location tracking on the
  /// first subscription and stops it automatically when all subscriptions are
  /// cancelled.
  ///
  /// Multiple callers sharing the same stream will share a single native
  /// tracking session using the [config] supplied by the first subscriber.
  ///
  /// Example:
  /// ```dart
  /// final sub = FlutterNativeLocation.getLocationStream(
  ///   LocationConfig(accuracy: LocationAccuracy.high),
  /// ).listen((position) {
  ///   print(position);
  /// });
  ///
  /// // Stop tracking
  /// await sub.cancel();
  /// ```
  static Stream<Position> getLocationStream(LocationConfig config) {
    return FlutterNativeLocationPlatform.instance.getLocationStream(config);
  }

  /// Returns the last known [Position], or null if unavailable.
  static Future<Position?> getLastLocation() {
    return FlutterNativeLocationPlatform.instance.getLastLocation();
  }

  /// Returns a freshly fetched [Position], or null if unavailable.
  static Future<Position?> getCurrentLocation() {
    return FlutterNativeLocationPlatform.instance.getCurrentLocation();
  }
}
