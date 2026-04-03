import 'package:flutter_native_location/flutter_native_location.dart';

class LocationConfig {
  /// The desired accuracy level for location updates.
  final LocationAccuracy accuracy;

  /// Emission interval for location updates.
  ///
  /// When set, the native GPS runs freely and the Dart layer samples the
  /// latest fix on a fixed clock tick — so you receive exactly one update
  /// per [timeLimit] duration regardless of how often the hardware fires.
  ///
  /// Set to `null` to forward every native event directly (default).
  final Duration? timeLimit;

  const LocationConfig({
    this.accuracy = LocationAccuracy.high,
    this.timeLimit,
  });

  /// Returns a copy of this config with the given fields replaced.
  LocationConfig copyWith({
    LocationAccuracy? accuracy,
    Duration? timeLimit,
  }) =>
      LocationConfig(
        accuracy: accuracy ?? this.accuracy,
        timeLimit: timeLimit ?? this.timeLimit,
      );

  @override
  String toString() =>
      'LocationConfig(accuracy: $accuracy, timeLimit: $timeLimit)';
}
