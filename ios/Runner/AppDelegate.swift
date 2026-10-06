import Flutter
import UIKit
import flutter_local_notifications
import workmanager_apple

/// Must match `_taskName` in lib/alerts.dart and BGTaskSchedulerPermittedIdentifiers in Info.plist.
private let backgroundCheckTask = "tantya.checkWatchlist"

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Show notifications while the app is open too, and route taps to Flutter.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate

    // Background refresh for watchlist alerts, setup results and the scanner. iOS decides
    // when it actually runs (often hourly or less); 15 min is only the earliest it may.
    // With UIScene these must be registered before didFinishLaunching returns.
    WorkmanagerPlugin.registerPeriodicTask(withIdentifier: backgroundCheckTask, earliestBeginInSeconds: NSNumber(value: 15 * 60))
    WorkmanagerPlugin.registerLaunchHandlers()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // Background work runs in a separate headless engine; give it the same plugins
    // (HTTP, shared_preferences, notifications) as the app.
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
