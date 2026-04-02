import Flutter
import CoreLocation

public class FlutterNativeLocationPlugin: NSObject, FlutterPlugin {

    var locationManager: LocationManager?
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
        instance.streamHandler.plugin = instance
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance.streamHandler)
    }

    // MARK: - MethodChannel Handler

    /// Routes incoming Flutter method calls to the native location manager.
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {

        case "getCurrentLocation":
            ensureManager().getCurrentLocation { map, errorMessage in
                if let err = errorMessage {
                    result(FlutterError(code: "LOCATION_ERROR", message: err, details: nil))
                } else {
                    result(map)
                }
            }

        case "getLastLocation":
            result(locationManager?.lastLocationMap)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Helpers

    /// Lazily creates the `LocationManager`, wiring location and error events to the stream handler.
    @discardableResult
    func ensureManager() -> LocationManager {
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

    weak var plugin: FlutterNativeLocationPlugin?
    private(set) var eventSink: FlutterEventSink?

    /// Called when Flutter subscribes to the event channel.
    /// Arguments contain tracking config: `accuracyLevel` (String).
    @objc public func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        eventSink = events

        let args = arguments as? [String: Any]
        let accuracyLevel = args?["accuracyLevel"] as? String ?? "high"

        let manager = plugin?.ensureManager()
        manager?.requestPermission { [weak self] status in
            guard status == "authorizedAlways" || status == "authorizedWhenInUse" else {
                self?.eventSink?(FlutterError(
                    code: "PERMISSION_DENIED",
                    message: "Location permission: \(status)",
                    details: nil
                ))
                return
            }
            manager?.startTracking(accuracyLevel: accuracyLevel)
        }

        return nil
    }

    /// Called when Flutter cancels its event channel subscription.
    @objc public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.locationManager?.stopTracking()
        eventSink = nil
        return nil
    }
}
