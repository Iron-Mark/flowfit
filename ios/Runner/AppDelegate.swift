import Flutter
import UIKit
import CoreLocation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Setup Geofence method/event channels
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let geofenceChannel = FlutterMethodChannel(name: "com.flowfit.geofence/native", binaryMessenger: controller.binaryMessenger)
    geofenceChannel.setMethodCallHandler({ (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      switch call.method {
      case "registerGeofence":
        // arguments: id, lat, lon, radius
        result(true)
      case "unregisterGeofence":
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    })

    let geofenceEvents = FlutterEventChannel(name: "com.flowfit.geofence/events", binaryMessenger: controller.binaryMessenger)
    geofenceEvents.setStreamHandler(nil) // stubbed; iOS native implementation should add event sink
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
