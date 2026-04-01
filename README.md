# flutter_native_location

A Flutter plugin for native GPS location tracking with configurable accuracy. Currently supports **iOS only**.

## Features

- 📍 Continuous location tracking via `CLLocationManager`
- 🎯 Accuracy filter — discard low-quality GPS fixes
- 🔋 Background location updates (screen-off tracking)
- 📡 Stream-based API — tracking starts on subscribe, stops on cancel
- 🛑 Native errors forwarded to Flutter as `PlatformException`

## Installation

```yaml
dependencies:
  flutter_native_location: ^0.2.0
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

> **Note:** Location permission is requested automatically when the stream is first subscribed to.

## Usage

### 1. Subscribe to the location stream

```dart
final sub = FlutterNativeLocation.getLocationStream(
  LocationConfig(
    accuracy: LocationAccuracy.high, // filter fixes worse than ~25 m
  ),
).listen(
  (Position pos) {
    print('${pos.latitude}, ${pos.longitude}');
    print('Speed: ${pos.speedKmh} km/h');
    print('Accuracy: ±${pos.accuracy} m');
  },
  onError: (error) {
    // PlatformException forwarded from native (e.g. permission denied)
    print('Location error: $error');
  },
);
```

### 2. Stop tracking

Cancel the subscription — tracking stops automatically when all subscribers cancel.

```dart
await sub.cancel();
```

### 3. One-shot location helpers

These work independently of the stream subscription.

```dart
// Last cached location (instant, no GPS fix needed)
final last = await FlutterNativeLocation.getLastLocation();

// Fresh location fix (may take a moment)
final current = await FlutterNativeLocation.getCurrentLocation();
```

### 4. Multiple subscribers

All subscribers share one native tracking session. Tracking starts when the first subscriber joins and stops when the last one cancels.

```dart
// Both receive the same location events from one native session
final subA = FlutterNativeLocation.getLocationStream(config).listen(...);
final subB = FlutterNativeLocation.getLocationStream(config).listen(...);

await subA.cancel(); // tracking continues (subB is still active)
await subB.cancel(); // tracking stops
```

## Configuration

### `LocationConfig`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `accuracy` | `LocationAccuracy` | `high` | GPS precision level and accuracy filter |
| `accuracyFilter` | `double?` | `null` | Custom max horizontal accuracy in metres (overrides `accuracy.thresholdMeters`) |
| `intervalSeconds` | `int` | `5` | Minimum seconds between emitted updates |

### `LocationAccuracy` values

| Value | Max horizontal accuracy | iOS `desiredAccuracy` |
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
| `speedKmh` | `double?` | Speed in km/h (computed from `speed`), -1 if invalid |

## Background Tracking

This plugin uses `CLLocationManager.startUpdatingLocation()` with `allowsBackgroundLocationUpdates = true` and `pausesLocationUpdatesAutomatically = false`. This ensures location updates continue reliably when the screen is off — unlike async/await-based APIs (e.g. `CLLocationUpdate.liveUpdates()`) which can be throttled by iOS's cooperative thread scheduler after ~90 seconds in the background.

**Required:** `UIBackgroundModes: location` in `Info.plist` and location permission set to **"Always"** in device Settings.

## Platform Support

| Platform | Support |
|---|---|
| iOS | ✅ |
| Android | 🔜 Planned |
