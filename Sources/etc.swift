import UIKit

class StackView<T: UIView>: UIStackView {
    convenience init(arrangedSubviews: [T]) {
        self.init(arrangedSubviews: arrangedSubviews as [UIView])
    }

    override func addArrangedSubview(_ view: UIView) {
        guard view is T else { fatalError("Expected view of type \(String(describing: T.self)) but got \(String(describing: type(of: view)))") }
        super.addArrangedSubview(view)
    }

    override func insertArrangedSubview(_ view: UIView, at stackIndex: Int) {
        guard view is T else { fatalError("Expected view of type \(String(describing: T.self)) but got \(String(describing: type(of: view)))") }
        super.insertArrangedSubview(view, at: stackIndex)
    }

    var views: [T] {
        return arrangedSubviews as! [T]
    }

    subscript(i: Int) -> T {
        get { return views[i] }
        set { insertArrangedSubview(newValue, at: i) }
    }
}
