import 'package:flutter_native_location/flutter_native_location.dart';

class LocationConfig {
  /// The interval in seconds between location updates.
  final int intervalSeconds;

  /// The desired accuracy level for location updates.
  final LocationAccuracy accuracy;

  /// If not provided, it will use the accuracy.thresholdMeters
  final double? accuracyFilter;

  const LocationConfig({
    this.intervalSeconds = 5,
    this.accuracy = LocationAccuracy.high,
    this.accuracyFilter,
  }) : assert(intervalSeconds > 0, 'intervalSeconds must be > 0');

  /// Returns the resolved accuracy threshold in metres to send to native.
  double get resolvedAccuracyFilter {
    return accuracyFilter ?? accuracy.thresholdMeters!;
  }

  /// Returns a copy of this config with the given fields replaced.
  LocationConfig copyWith({
    int? intervalSeconds,
    LocationAccuracy? accuracy,
    double? accuracyFilter,
  }) => LocationConfig(
    intervalSeconds: intervalSeconds ?? this.intervalSeconds,
    accuracy: accuracy ?? this.accuracy,
    accuracyFilter: accuracyFilter ?? this.accuracyFilter,
  );

  @override
  String toString() =>
      'LocationConfig(intervalSeconds: $intervalSeconds, '
      'accuracy: $accuracy (${resolvedAccuracyFilter}m))';
}
