import SwiftUI
import FirebaseCore       // FirebaseApp.configure()
import GoogleSignIn       // GIDConfiguration, GIDSignIn

// ——————————————————————————————
// 1) AppDelegate
// ——————————————————————————————
//class AppDelegate: NSObject, UIApplicationDelegate {
//    func application(
//        _ application: UIApplication,
//        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
//    ) -> Bool {
//        // Initialize Firebase
//        FirebaseApp.configure()
//        return true
//    }
//
//    // Handle the redirect from the Google Sign-In flow
//    func application(
//      _ app: UIApplication,
//      open url: URL,
//      options: [UIApplication.OpenURLOptionsKey : Any] = [:]
//    ) -> Bool {
//        return GIDSignIn.sharedInstance.handle(url)
//    }
//}
// 2) Main App — no guard/fatalError here!
// ——————————————————————————————
@main
struct TagAlongApp: App {
    let baseURL = "http://10.0.0.31:8000";
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var groupVM = GroupViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(groupVM)
        }
    }
}
