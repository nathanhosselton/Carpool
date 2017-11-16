import CarpoolKit

//MARK: Model

extension Event {
    var prettyDescription: NSAttributedString {
        let formatter: DateFormatter = .forEvents
        return NSMutableAttributedString().bold(description).normal(" at ").bold(formatter.string(from: time))
    }

    var prettyDate: NSAttributedString {
        let dateF = DateFormatter("EEE, MMM d")
        let timeF = DateFormatter.forEvents
        return NSMutableAttributedString().bold(dateF.string(from: time)).normal(" at ").bold(timeF.string(from: time))
    }

    var prettyEndDate: String? {
        guard let date = endTime else { return nil }
        return DateFormatter.forEvents.string(from: date)
    }
}

import MapKit.MKAnnotation

extension Event {
    class Annotation: NSObject, MKAnnotation {
        let coordinate: CLLocationCoordinate2D
        let title: String?
        let subtitle: String?

        init?(event: Event) {
            guard let coord = event.clLocation?.coordinate else { return nil }
            self.coordinate = coord
            self.title = event.description
            self.subtitle = event.owner.name
            super.init()
        }
    }

    var annotation: Annotation? {
        return Annotation(event: self)
    }
}

extension Trip {
    //Because `prettyChildren` didn't sound ok
    var prettyPrintedChildren: String {
        return children.map{ $0.name }.joined(separator: ", ")
    }
}

extension Trip {
    var hasUnclaimedLegs: Bool {
        return !dropOffIsClaimed || !pickUpIsClaimed
    }

    var dropOffIsClaimed: Bool {
        return dropOff != nil
    }

    var pickUpIsClaimed: Bool {
        return pickUp != nil
    }

    var canModifyDropoff: Bool {
        return canModify(dropOff)
    }

    var canModifyPickup: Bool {
        return canModify(pickUp)
    }

    private func canModify(_ leg: Leg?) -> Bool {
        guard let leg = leg else { return true }
        return leg.driver.isMe || event.owner.isMe
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



//MARK: UI

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



//MARK: Foundation

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

func +(lhs: String, rhs: NSAttributedString) -> NSAttributedString {
    return NSMutableAttributedString().normal(lhs) + rhs
}

func +(lhs: NSAttributedString, rhs: String) -> NSAttributedString {
    return lhs + NSMutableAttributedString().normal(rhs)
}
