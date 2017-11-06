import Foundation
import UIKit.UIFont

// From: https://stackoverflow.com/questions/28496093/making-text-bold-using-attributed-string-in-swift
extension NSMutableAttributedString {
    @discardableResult func bold(_ text: String) -> NSMutableAttributedString {
        let attrs: [NSAttributedStringKey: Any] = [.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)]
        let boldString = NSMutableAttributedString(string:text, attributes: attrs)
        append(boldString)

        return self
    }

    @discardableResult func normal(_ text: String) -> NSMutableAttributedString {
        let attrs: [NSAttributedStringKey: Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize)]
        let normal = NSAttributedString(string: text, attributes: attrs)
        append(normal)

        return self
    }
}
