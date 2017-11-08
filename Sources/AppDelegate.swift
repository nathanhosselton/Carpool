import UIKit
import FirebaseCommunity

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
//        Auth.auth().signInAnonymously { print(#function, $0 ?? $1 ?? "idfk") }

        window = UIWindow()
        window!.backgroundColor = .white
        window!.rootViewController = UINavigationController(rootViewController: ScheduleViewController(style: .plain))
        window!.makeKeyAndVisible()

        return true
    }

}
