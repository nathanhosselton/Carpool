public struct User: Codable, Keyed {
    var key: String!
    public let name: String?
}

extension User: Equatable {
    public static func ==(lhs: User, rhs: User) -> Bool {
        return lhs.key == rhs.key
    }
}

extension User: Hashable {
    public var hashValue: Int {
        return key.hashValue
    }
}

extension User: Comparable {
    public static func <(lhs: User, rhs: User) -> Bool {
        return lhs.name ?? "" < rhs.name ?? ""
    }
}
