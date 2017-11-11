import UIKit

extension UIView {
    func addSubviews(_ views: [UIView]) {
        views.forEach(addSubview)
    }
}

extension UIViewController {
    func show(_ e: UserError) {
        let alert = UIAlertController(title: "Whoops", message: e.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Gotcha", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
}
