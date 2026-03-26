import Flutter
import CoreLocation

public class FlutterNativeLocationPlugin: NSObject, FlutterPlugin {

    private var locationManager: LocationManager?
    private let streamHandler = LocationStreamHandler()

    // MARK: - Registration

    /// Registers the plugin's method channel and event channel with the Flutter engine.
    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "flutter_native_location/methods",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "flutter_native_location/location_stream",
            binaryMessenger: registrar.messenger()
        )

        let instance = FlutterNativeLocationPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance.streamHandler)
    }

    // MARK: - MethodChannel Handler

    /// Routes incoming Flutter method calls to the native location manager.
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {

        case "requestPermission":
            ensureManager().requestPermission { status in
                result(status)
            }

        case "startTracking":
            let args          = call.arguments as? [String: Any]
            let filter        = args?["accuracyFilter"] as? Double ?? 50
            let accuracyLevel = args?["accuracyLevel"] as? String ?? "high"
            ensureManager().startTracking(accuracyFilter: filter,
                                          accuracyLevel: accuracyLevel)
            result(nil)

        case "pauseTracking":
            locationManager?.pauseTracking()
            result(nil)

        case "resumeTracking":
            locationManager?.resumeTracking()
            result(nil)

        case "stopTracking":
            locationManager?.stopTracking()
            result(nil)

        case "getTrackingState":
            result(locationManager?.trackingStateString ?? "idle")

        case "getCurrentLocation":
            ensureManager().getCurrentLocation { map, errorMessage in
                if let err = errorMessage {
                    result(FlutterError(code: "LOCATION_ERROR", message: err, details: nil))
                } else {
                    result(map)
                }
            }

        case "getLastLocation":
            result(ensureManager().lastLocationMap)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Helpers

    /// Lazily creates the `LocationManager`, wiring location and error events to the stream handler.
    @discardableResult
    private func ensureManager() -> LocationManager {
        if let manager = locationManager { return manager }
        let manager = LocationManager(
            onLocation: { [weak self] locationMap in
                self?.streamHandler.eventSink?(locationMap)
            },
            onError: { [weak self] code, message in
                let flutterError = FlutterError(code: code, message: message, details: nil)
                self?.streamHandler.eventSink?(flutterError)
            }
        )
        locationManager = manager
        return manager
    }
}

// MARK: - LocationStreamHandler

@objc final class LocationStreamHandler: NSObject, FlutterStreamHandler {

    private(set) var eventSink: FlutterEventSink?

    /// Called when Flutter subscribes to the event channel.
    @objc public func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        eventSink = events
        return nil
    }

    /// Called when Flutter cancels its event channel subscription.
    @objc public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}
