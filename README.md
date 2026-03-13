# flutter_native_location

A Flutter plugin for native GPS location tracking with configurable interval and accuracy filter. Currently supports **iOS only**.

## Features

- 📍 Location tracking with a configurable time interval
- 🎯 Accuracy filter — discard low-quality GPS fixes
- 🔋 Background location updates via `CLLocationManager`
- ⏸ Pause / resume / stop controls
- 📡 Real-time location stream via `EventChannel`
- 🛑 Native errors forwarded to Flutter as `PlatformException`

## Installation

```yaml
dependencies:
  flutter_native_location: ^0.1.0
```

## iOS Setup

Add the following keys to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Required to track your location while the app is open.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Required to track your location in the background.</string>

<key>UIBackgroundModes</key>
<array>
  <string>location</string>
</array>
```

## Usage

### 1. Initialise once (e.g. in `main.dart`)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterNativeLocation.init(
    LocationConfig(
      intervalSeconds: 5,          // emit a location every 5 seconds
      accuracy: LocationAccuracy.high,  // filter fixes worse than ~25 m
      autoStart: true,             // start tracking right after permission is granted
    ),
  );

  runApp(const MyApp());
}
```

### 2. Access the singleton anywhere

```dart
final tracker = FlutterNativeLocation.instance;
```

### 3. Listen to the location stream

```dart
tracker.locationStream.listen(
  (Position point) {
    print('${point.latitude}, ${point.longitude}');
    print('Speed: ${point.speedKmh} km/h');
    print('Accuracy: ±${point.accuracy} m');
  },
  onError: (error) {
    // PlatformException forwarded from native (e.g. permission denied)
    print('Location error: $error');
  },
);
```

### 4. Tracking controls

```dart
await tracker.startTracking();   // start (or restart)
await tracker.pauseTracking();   // pause emission, keep CLLocationManager alive
await tracker.resumeTracking();  // resume after pause
await tracker.stopTracking();    // stop and release resources
```

### 5. Other helpers

```dart
// Check current state
print(tracker.state); // TrackingState.idle | tracking | paused | error

// Fetch authoritative state from native
final state = await tracker.getTrackingState();

// Get last known position
final last = await tracker.getLastLocation();

// Reconfigure on the fly (restarts tracking if active)
await tracker.reconfigure(
  LocationConfig(intervalSeconds: 10, accuracy: LocationAccuracy.medium),
);
```

## Configuration

| Parameter | Type | Default | Description |
|---|---|---|---|
| `intervalSeconds` | `int` | `5` | How often a location snapshot is emitted (seconds) |
| `accuracy` | `LocationAccuracy` | `high` | GPS fix quality filter |
| `autoStart` | `bool` | `false` | Start tracking automatically after `init()` |

### `LocationAccuracy` values

| Value | Max horizontal accuracy | iOS desiredAccuracy |
|---|---|---|
| `best` | ~5 m | `kCLLocationAccuracyBest` |
| `high` | ~25 m | `kCLLocationAccuracyNearestTenMeters` |
| `medium` | ~100 m | `kCLLocationAccuracyHundredMeters` |
| `low` | ~1000 m | `kCLLocationAccuracyKilometer` |
| `lowest` | ~3000 m | `kCLLocationAccuracyThreeKilometers` |

## `Position` fields

| Field | Type | Description |
|---|---|---|
| `latitude` | `double?` | Degrees |
| `longitude` | `double?` | Degrees |
| `timestamp` | `DateTime?` | Time of the fix |
| `accuracy` | `double?` | Horizontal accuracy in metres |
| `altitude` | `double?` | Metres above sea level |
| `altitudeAccuracy` | `double?` | Vertical accuracy in metres |
| `heading` | `double?` | Direction of travel (degrees, 0–360), -1 if invalid |
| `headingAccuracy` | `double?` | Heading accuracy in degrees |
| `speed` | `double?` | Speed in m/s, -1 if invalid |
| `speedAccuracy` | `double?` | Speed accuracy in m/s |
| `speedKmh` | `double?` | Speed in km/h (computed from `speed`), null if invalid |

## Platform Support

| Platform | Support |
|---|---|
| iOS | ✅ |
| Android | 🔜 Planned |
