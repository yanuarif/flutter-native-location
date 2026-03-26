import CoreLocation
import Foundation

class LocationManager: NSObject {

    private let onLocation: ([String: Any]) -> Void
    private let onError: (_ code: String, _ message: String) -> Void

    private let clManager = CLLocationManager()
    private var accuracyFilter: Double = 50
    private var latestLocation: CLLocation?
    private var previousLocation: CLLocation?

    private var updateTask: Task<Void, Never>?
    private var backgroundSession: Any?

    private(set) var trackingStateString: String = "idle"
    var lastLocationMap: [String: Any]? {
        let locToUse = latestLocation ?? clManager.location
        return locToUse.map { Self.toMap($0, previousLoc: previousLocation) }
    }

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

    /// Starts location updates with accuracy filter, and iOS accuracy level.
    func startTracking(accuracyFilter: Double, accuracyLevel: String = "high") {
        let status = clManager.authorizationStatus
        guard status == .authorizedAlways || status == .authorizedWhenInUse else {
            onError("PERMISSION_DENIED", "Location permission not granted. Status: \(status.rawValue)")
            return
        }

        self.accuracyFilter  = accuracyFilter

        clManager.desiredAccuracy                 = Self.toDesiredAccuracy(accuracyLevel)
        clManager.allowsBackgroundLocationUpdates    = true
        clManager.pausesLocationUpdatesAutomatically = false
        clManager.showsBackgroundLocationIndicator   = true

        trackingStateString = "tracking"

        if #available(iOS 18.0, *) {
            startLiveUpdates()
        } else {
            clManager.startUpdatingLocation()
        }
    }

    @available(iOS 18.0, *)
    private func startLiveUpdates() {
        backgroundSession = CLBackgroundActivitySession()
        updateTask?.cancel()
        updateTask = Task {
            do {
                let updates = CLLocationUpdate.liveUpdates()
                for try await update in updates {
                    guard !Task.isCancelled else { break }
                    if let loc = update.location {
                        self.handleNewLocation(loc)
                    }
                }
            } catch {
                self.onError("LIVE_UPDATE_FAILED", error.localizedDescription)
            }
        }
    }

    /// Pauses location emission without stopping CLLocationManager or Task (for smooth resume).
    func pauseTracking() {
        trackingStateString = "paused"
    }

    /// Resumes location emission after a pause.
    func resumeTracking() {
        guard trackingStateString == "paused" else { return }
        trackingStateString = "tracking"
    }

    /// Stops location updates and releases background permission.
    func stopTracking() {
        trackingStateString = "idle"
        
        if #available(iOS 18.0, *) {
            updateTask?.cancel()
            updateTask = nil
            (backgroundSession as? CLBackgroundActivitySession)?.invalidate()
            backgroundSession = nil
        }
        
        clManager.stopUpdatingLocation()
        clManager.allowsBackgroundLocationUpdates = false
    }

    // MARK: - Private

    private func handleNewLocation(_ loc: CLLocation) {
        if accuracyFilter > 0 {
            guard loc.horizontalAccuracy >= 0,
                  loc.horizontalAccuracy <= accuracyFilter else { return }
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Only update previousLocation if it's a new point in time
            if let latest = self.latestLocation, latest.timestamp != loc.timestamp {
                self.previousLocation = latest
            }
            self.latestLocation = loc
            
            self.emitLatestLocation()
        }
    }

    private func emitLatestLocation() {
        guard trackingStateString == "tracking" else { return }
        guard let loc = latestLocation else { return }
        let map = Self.toMap(loc, previousLoc: previousLocation)
        self.onLocation(map)
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
    static func toMap(_ loc: CLLocation, previousLoc: CLLocation? = nil) -> [String: Any] {
        var finalSpeed = loc.speed
        var finalHeading = loc.course
        
        if let prev = previousLoc {
            let distance = loc.distance(from: prev)
            let timeDelta = loc.timestamp.timeIntervalSince(prev.timestamp)
            
            // If native speed is invalid (< 0) or unrealistically high (e.g., > 150 m/s (~540 km/h) which indicates GPS noise)
            if timeDelta > 0 && distance >= 0 {
                let calculatedSpeed = distance / timeDelta
                
                if finalSpeed < 0 || finalSpeed > 150 {
                    finalSpeed = calculatedSpeed
                }
                
                // Fallback for invalid heading (< 0) using bearing calculation
                if finalHeading < 0 {
                    finalHeading = calculateBearing(from: prev.coordinate, to: loc.coordinate)
                }
            }
        }
        
        return [
            "longitude":        loc.coordinate.longitude,
            "latitude":         loc.coordinate.latitude,
            "timestamp":        Int64(loc.timestamp.timeIntervalSince1970 * 1000),
            "accuracy":         loc.horizontalAccuracy,
            "altitude":         loc.altitude,
            "altitudeAccuracy": loc.verticalAccuracy,
            "heading":          finalHeading,
            "headingAccuracy":  loc.courseAccuracy,
            "speed":            finalSpeed,
            "speedAccuracy":    loc.speedAccuracy,
            "speedKmh":         finalSpeed >= 0 ? finalSpeed * 3.6 : -1.0,
        ]
    }

    /// Calculates bearing (in degrees, true North) from one coordinate to another
    static func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lon1 = from.longitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let lon2 = to.longitude * .pi / 180
        
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        
        var degrees = radiansBearing * 180 / .pi
        if degrees < 0 {
            degrees += 360
        }
        return degrees
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
        handleNewLocation(loc)
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
