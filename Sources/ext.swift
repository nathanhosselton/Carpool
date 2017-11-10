//
//  ext.swift
//  Carpool
//
//  Created by Nathan Hosselton on 11/6/17.
//  Copyright © 2017 Nathan Hosselton. All rights reserved.
//

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

extension String {
    var chuzzled: String? {
        let rv = trimmingCharacters(in: .whitespacesAndNewlines)
        return rv.isEmpty ? nil : rv
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

