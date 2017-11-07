import Foundation
import UIKit.UIFont

// Modified from: https://stackoverflow.com/questions/28496093/making-text-bold-using-attributed-string-in-swift
extension NSMutableAttributedString {
    @discardableResult func bold(_ text: String) -> NSMutableAttributedString {
        let bold: [NSAttributedStringKey: UIFont] = [.font: .boldSystemFont(ofSize: UIFont.systemFontSize)]
        append(NSMutableAttributedString(string:text, attributes: bold))
        return self
    }

    @discardableResult func normal(_ text: String) -> NSMutableAttributedString {
        let normal: [NSAttributedStringKey: UIFont] = [.font: .systemFont(ofSize: UIFont.systemFontSize)]
        append(NSAttributedString(string: text, attributes: normal))
        return self
    }
}

extension NSCoder {
    static var null: NSCoder {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.finishEncoding()
        return NSKeyedUnarchiver(forReadingWith: data as Data)
    }
}

extension UIView {
    func addSubviews(_ views: [UIView]) {
        views.forEach(addSubview)
    }
}
