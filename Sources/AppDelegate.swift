import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        window = UIWindow()
        window!.backgroundColor = .white
        window!.rootViewController = UINavigationController(rootViewController: ScheduleViewController(style: .plain))
        window!.makeKeyAndVisible()

        return true
    }

}
