import CarpoolKit

extension Event {
    var prettyDescription: NSAttributedString {
        let formatter: DateFormatter = .forEvents
        return NSMutableAttributedString().bold(description).normal(" at ").bold(formatter.string(from: time))
    }
}

extension DateFormatter {
    static var forEvents: DateFormatter {
        return DateFormatter("h:mm a")
    }

    convenience init(_ format: String) {
        self.init()
        dateFormat = format
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

extension String {
    var chuzzled: String? {
        let rv = trimmingCharacters(in: .whitespacesAndNewlines)
        return rv.isEmpty ? nil : rv
    }
}

// Modified from: https://stackoverflow.com/questions/28496093/making-text-bold-using-attributed-string-in-swift
extension NSMutableAttributedString {
    @discardableResult
    func bold(_ text: String) -> NSMutableAttributedString {
        let bold: [NSAttributedStringKey: UIFont] = [.font: .boldSystemFont(ofSize: UIFont.systemFontSize)]
        append(NSMutableAttributedString(string:text, attributes: bold))
        return self
    }

    @discardableResult
    func normal(_ text: String) -> NSMutableAttributedString {
        let normal: [NSAttributedStringKey: UIFont] = [.font: .systemFont(ofSize: UIFont.systemFontSize)]
        append(NSAttributedString(string: text, attributes: normal))
        return self
    }
}

//`phone` removed for now
//extension User {
//    var prettyPhone: String {
//        return String(phone).map{ String($0) }.reduce(into: "", { (result, digit) in
//            struct Counter { static var cc = 1 }
//            var needsDash: Bool { return Counter.cc % 3 == 0 && Counter.cc < 7 }
//            result += needsDash ? "\(digit)-" : digit
//            Counter.cc += 1
//        })
//    }
//}

