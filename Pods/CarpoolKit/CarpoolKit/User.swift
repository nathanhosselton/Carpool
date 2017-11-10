import FirebaseCommunity

public struct User: Codable, Keyed {
    var key: String!
    public let name: String?
    public let _children: [Child]?  // optional for decodable

    enum CodingKeys: String, CodingKey {
        case key
        case name
        case _children = "children"
    }

    public var children: [Child] { return _children ?? [] }

    public var isMe: Bool {
        return Auth.auth().currentUser?.uid == key
    }
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
