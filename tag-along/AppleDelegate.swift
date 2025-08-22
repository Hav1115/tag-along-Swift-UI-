//
//  AppleDelegate.swift
//  tag-along
//
//  Created by Havish Komatreddy on 7/29/25.
//

import UIKit
import UserNotifications
import FirebaseCore   // if you’re already using Firebase
// …any other imports…
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // 1. Configure Firebase (if you’re using it)
    FirebaseApp.configure()

    // 2. Register for notifications & set delegate
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        print("✅ Notification permission granted? \(granted) – \(error?.localizedDescription ?? "no error")")
    }
    center.delegate = self    // ← hook in here
    application.registerForRemoteNotifications()

    return true
  }

  // 3. This method fires when a notification arrives **while your app is in the foreground**:
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    print("🔔 [AppDelegate] willPresent: \(notification.request.content.body)")
    // Show a banner + play sound even if the app is open:
    completionHandler([.banner, .sound, .badge])
  }

  // (optional) handle taps on the notification
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    print("🏷️ User tapped notification with id: \(response.notification.request.identifier)")
    completionHandler()
  }
}
