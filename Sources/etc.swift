import UIKit

class StackView<T: UIView>: UIStackView {
    convenience init(arrangedSubviews: [T]) {
        self.init(arrangedSubviews: arrangedSubviews as [UIView])
    }

    var views: [T] {
        return subviews as! [T]
    }

    subscript(i: Int) -> T {
        get { return views[i] }
    }
}
