import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController

    // Debug Mode Channel
    let debugChannel = FlutterMethodChannel(name: "com.techwings.fmiscupaap3", binaryMessenger: controller.binaryMessenger)

    debugChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "isDeveloperModeEnabled" {
        // iOS does not expose this setting like Android
        // You can default to false or simulate behavior
        result(false)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // Alarm Channel
    let alarmChannel = FlutterMethodChannel(name: "alarm_channel", binaryMessenger: controller.binaryMessenger)

    alarmChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "setAlarms":
        print("setAlarms called on iOS")
        result("Alarm set (stub) on iOS")

      case "requestExactAlarmPermission":
        print("requestExactAlarmPermission called on iOS")
        result("Not required on iOS")

      case "cancelAlarms":
        print("cancelAlarms called on iOS")
        result("Alarms cancelled (stub) on iOS")

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
