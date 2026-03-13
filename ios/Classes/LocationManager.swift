import CoreLocation
import Foundation

class LocationManager: NSObject {

    private let onLocation: ([String: Any]) -> Void
    private let onError: (_ code: String, _ message: String) -> Void

    private let clManager = CLLocationManager()
    private var timer: Timer?
    private var intervalSeconds: TimeInterval = 5
    private var accuracyFilter: Double = 50
    private var latestLocation: CLLocation?

    private(set) var trackingStateString: String = "idle"
    var lastLocationMap: [String: Any]? { latestLocation.map(Self.toMap) }

    // MARK: - Init

    init(
        onLocation: @escaping ([String: Any]) -> Void,
        onError: @escaping (_ code: String, _ message: String) -> Void
    ) {
        self.onLocation = onLocation
        self.onError = onError
        super.init()
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyBest
        clManager.distanceFilter  = kCLDistanceFilterNone
    }

    // MARK: - Permission

    /// Requests location permission and calls completion with the resulting status string.
    func requestPermission(completion: @escaping (String) -> Void) {
        permissionCompletion = completion
        switch clManager.authorizationStatus {
        case .authorizedAlways:
            permissionCompletion = nil
            completion("authorizedAlways")
        case .authorizedWhenInUse:
            permissionCompletion = nil
            completion("authorizedWhenInUse")
        case .denied, .restricted:
            permissionCompletion = nil
            completion("denied")
        default:
            clManager.requestAlwaysAuthorization()
        }
    }

    private var permissionCompletion: ((String) -> Void)?

    // MARK: - Tracking

    /// Starts location updates with a timer-based emission interval, accuracy filter, and iOS accuracy level.
    func startTracking(intervalSeconds: Int, accuracyFilter: Double, accuracyLevel: String = "high") {
        let status = clManager.authorizationStatus
        guard status == .authorizedAlways || status == .authorizedWhenInUse else {
            onError("PERMISSION_DENIED", "Location permission not granted. Status: \(status.rawValue)")
            return
        }

        self.intervalSeconds = TimeInterval(intervalSeconds)
        self.accuracyFilter  = accuracyFilter

        clManager.desiredAccuracy                 = Self.toDesiredAccuracy(accuracyLevel)
        clManager.allowsBackgroundLocationUpdates    = true
        clManager.pausesLocationUpdatesAutomatically = false
        clManager.showsBackgroundLocationIndicator   = true
        clManager.startUpdatingLocation()

        trackingStateString = "tracking"
        scheduleTimer()
    }

    /// Pauses timer-based emission without stopping CLLocationManager.
    func pauseTracking() {
        timer?.invalidate()
        timer = nil
        trackingStateString = "paused"
    }

    /// Resumes timer-based emission after a pause.
    func resumeTracking() {
        guard trackingStateString == "paused" else { return }
        trackingStateString = "tracking"
        scheduleTimer()
    }

    /// Stops location updates and releases CLLocationManager background permission.
    func stopTracking() {
        timer?.invalidate()
        timer = nil
        clManager.stopUpdatingLocation()
        clManager.allowsBackgroundLocationUpdates = false
        trackingStateString = "idle"
    }

    // MARK: - Private

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: intervalSeconds,
                                      repeats: true) { [weak self] _ in
            self?.emitLatestLocation()
        }
    }

    private func emitLatestLocation() {
        guard let loc = latestLocation else { return }
        let map = Self.toMap(loc)
        DispatchQueue.main.async { self.onLocation(map) }
    }

    // MARK: - Helpers

    /// Maps a Flutter `LocationAccuracy` enum name to a `CLLocationAccuracy` constant.
    static func toDesiredAccuracy(_ level: String) -> CLLocationAccuracy {
        switch level {
        case "best":    return kCLLocationAccuracyBest
        case "high":    return kCLLocationAccuracyNearestTenMeters
        case "medium":  return kCLLocationAccuracyHundredMeters
        case "low":     return kCLLocationAccuracyKilometer
        case "lowest":  return kCLLocationAccuracyThreeKilometers
        default:        return kCLLocationAccuracyBest
        }
    }

    /// Serialises a `CLLocation` into a map compatible with the Flutter platform channel codec.
    static func toMap(_ loc: CLLocation) -> [String: Any] {
        return [
            "longitude":        loc.coordinate.longitude,
            "latitude":         loc.coordinate.latitude,
            "timestamp":        Int64(loc.timestamp.timeIntervalSince1970 * 1000),
            "accuracy":         loc.horizontalAccuracy,
            "altitude":         loc.altitude,
            "altitudeAccuracy": loc.verticalAccuracy,
            "heading":          loc.course,
            "headingAccuracy":  loc.courseAccuracy,
            "speed":            loc.speed,
            "speedAccuracy":    loc.speedAccuracy,
            "speedKmh":         loc.speed >= 0 ? loc.speed * 3.6 : -1.0,
        ]
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    /// Delivers the resolved permission status to any pending `requestPermission` callback.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status: String
        switch manager.authorizationStatus {
        case .authorizedAlways:      status = "authorizedAlways"
        case .authorizedWhenInUse:   status = "authorizedWhenInUse"
        case .denied, .restricted:   status = "denied"
        default:                     status = "notDetermined"
        }
        permissionCompletion?(status)
        permissionCompletion = nil
    }

    /// Stores the latest qualifying location; filtered by `accuracyFilter`. Updated on the main thread.
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }

        if accuracyFilter > 0 {
            guard loc.horizontalAccuracy >= 0,
                  loc.horizontalAccuracy <= accuracyFilter else { return }
        }

        DispatchQueue.main.async {
            self.latestLocation = loc
        }
    }

    /// Forwards CLLocationManager errors to Flutter via the `onError` closure.
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        let clError = error as? CLError
        let code    = clError.map { "CL_ERROR_\($0.code.rawValue)" } ?? "LOCATION_FAILED"
        let message = error.localizedDescription
        DispatchQueue.main.async { self.onError(code, message) }
    }
}
