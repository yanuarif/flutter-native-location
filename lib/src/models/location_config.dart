import 'package:flutter_native_location/flutter_native_location.dart';

class LocationConfig {
  /// The desired accuracy level for location updates.
  final LocationAccuracy accuracy;

  /// Maximum time to wait between consecutive location updates.
  ///
  /// If no update is received within this duration, the stream emits a
  /// [TimeoutException] and closes. The timer resets on every received update.
  /// Set to `null` to disable the timeout (default).
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
