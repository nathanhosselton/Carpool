public struct User {
    let id: String
    public let name: String
    public let phone: Int

    public static var current: User {
        let name = UserDefaults.standard.string(forKey: "username") ?? "Anonymous Parent"
        return User(id: "self", name: name, phone: 0)
    }
}

extension User: Equatable {
    public static func ==(lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}

extension User: Hashable {
    public var hashValue: Int {
        return id.hashValue
    }
}

extension User: Comparable {
    public static func <(lhs: User, rhs: User) -> Bool {
        return lhs.name < rhs.name
    }
}
