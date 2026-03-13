class Position {
  String? id;
  double? longitude;
  double? latitude;
  DateTime? timestamp;
  double? accuracy;
  double? altitude;
  double? altitudeAccuracy;
  double? heading;
  double? headingAccuracy;
  double? speed;
  double? speedAccuracy;
  double? speedKmh;

  Position({
    this.id,
    this.longitude,
    this.latitude,
    this.timestamp,
    this.accuracy,
    this.altitude,
    this.altitudeAccuracy,
    this.heading,
    this.headingAccuracy,
    this.speed,
    this.speedAccuracy,
    this.speedKmh,
  });

  /// Deserialises a platform channel map into a [Position].
  ///
  /// [timestamp] is expected as milliseconds since epoch (Int64 from native).
  /// [speedKmh] is computed from [speed] (m/s) if not provided directly.
  factory Position.fromJson(Map<String, dynamic> json) {
    DateTime? ts;
    final rawTs = json['timestamp'];
    if (rawTs != null) {
      ts = DateTime.fromMillisecondsSinceEpoch((rawTs as num).toInt());
    }

    double? speedKmh;
    final rawSpeedKmh = json['speedKmh'];
    if (rawSpeedKmh != null) {
      speedKmh = (rawSpeedKmh as num).toDouble();
    } else {
      final rawSpeed = json['speed'];
      if (rawSpeed != null) {
        final speedMs = (rawSpeed as num).toDouble();
        speedKmh = speedMs >= 0 ? speedMs * 3.6 : null;
      }
    }

    return Position(
      id: json['id'] as String?,
      longitude: (json['longitude'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      timestamp: ts,
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      altitudeAccuracy: (json['altitudeAccuracy'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      headingAccuracy: (json['headingAccuracy'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      speedAccuracy: (json['speedAccuracy'] as num?)?.toDouble(),
      speedKmh: speedKmh,
    );
  }

  /// Serialises this [Position] to a map.
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'longitude': longitude,
    'latitude': latitude,
    'timestamp': timestamp?.millisecondsSinceEpoch,
    'accuracy': accuracy,
    'altitude': altitude,
    'altitudeAccuracy': altitudeAccuracy,
    'heading': heading,
    'headingAccuracy': headingAccuracy,
    'speed': speed,
    'speedAccuracy': speedAccuracy,
    'speedKmh': speedKmh,
  };
}
