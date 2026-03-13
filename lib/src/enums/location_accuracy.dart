enum LocationAccuracy {
  lowest,
  low,
  medium,
  high,
  best,
  custom;

  /// Returns the maximum acceptable horizontal accuracy in metres, or null for [custom].
  double? get thresholdMeters => switch (this) {
    LocationAccuracy.lowest => 3000,
    LocationAccuracy.low    => 1000,
    LocationAccuracy.medium => 100,
    LocationAccuracy.high   => 25,
    LocationAccuracy.best   => 5,
    LocationAccuracy.custom => null,
  };
}
