import UIKit

extension UIView {
    func addSubviews(_ views: [UIView]) {
        views.forEach(addSubview)
    }
}

extension UIBarButtonItem {
    var isHidden: Bool {
        set {
            isEnabled = !newValue
            tintColor = isEnabled ? nil : .clear
        }
        get { return isEnabled && tintColor == nil }
    }
}

extension UIViewController {
    func show(_ e: UserError) {
        let alert = UIAlertController(title: "Whoops", message: e.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Gotcha", style: .cancel, handler: nil))
        present(alert, animated: true)
    }

    func show(_ e: Swift.Error) {
        let msg = "Sorry about that. Here's some more info in case it helps:\n\n\(e.localizedDescription)"
        let alert = UIAlertController(title: "Something broke", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Gotcha", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
}
