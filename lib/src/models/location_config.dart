import 'package:flutter_native_location/flutter_native_location.dart';

class LocationConfig {
  /// The desired accuracy level for location updates.
  final LocationAccuracy accuracy;

  const LocationConfig({this.accuracy = LocationAccuracy.high});

  /// Returns a copy of this config with the given fields replaced.
  LocationConfig copyWith({LocationAccuracy? accuracy}) =>
      LocationConfig(accuracy: accuracy ?? this.accuracy);

  @override
  String toString() => 'LocationConfig(accuracy: $accuracy)';
}
