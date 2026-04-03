## 0.2.2 - 2026-04-03
* Fix iOS location updates to respect the `timeLimit` interval.

## 0.2.1 - 2026-04-03
* Add `timeLimit` to `LocationConfig` to allow setting a timeout for location updates.

## 0.2.0 - 2026-04-01
* Refactor: migrate to stream-based location tracking and remove singleton dependency.

## 0.1.3 - 2026-03-27
* Fix iOS location updates to respect the `intervalSeconds` frequency.

## 0.1.2 - 2026-03-26
* Implement `getLastLocation` fallback logic for iOS.

## 0.1.1 - 2026-03-26
* Fix speed and heading calculation

## 0.1.0 - 2026-03-13
* Initial release with iOS support.
* Location tracking with configurable interval and accuracy filter.
* Background location updates via `CLLocationManager`.
* Pause, resume, and stop tracking controls.
* Location permission request handling.