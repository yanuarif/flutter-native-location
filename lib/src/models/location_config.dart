import 'package:flutter_native_location/flutter_native_location.dart';

class LocationConfig {
  final int intervalSeconds;
  final LocationAccuracy accuracy;
  final bool autoStart;

  const LocationConfig({
    this.intervalSeconds = 5,
    this.accuracy = LocationAccuracy.high,
    this.autoStart = false,
  }) : assert(intervalSeconds > 0, 'intervalSeconds must be > 0');

  /// Returns the resolved accuracy threshold in metres to send to native.
  double get resolvedAccuracyFilter {
    return accuracy.thresholdMeters!;
  }

  /// Returns a copy of this config with the given fields replaced.
  LocationConfig copyWith({
    int? intervalSeconds,
    LocationAccuracy? accuracy,
    bool? autoStart,
  }) => LocationConfig(
    intervalSeconds: intervalSeconds ?? this.intervalSeconds,
    accuracy: accuracy ?? this.accuracy,
    autoStart: autoStart ?? this.autoStart,
  );

  @override
  String toString() =>
      'LocationConfig(intervalSeconds: $intervalSeconds, '
      'accuracy: $accuracy (${resolvedAccuracyFilter}m), '
      'autoStart: $autoStart)';
}
