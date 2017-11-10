public struct Child: Codable, Keyed {
    var key: String!

    public let name: String
}

extension Child {
    func json() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        return try JSONSerialization.jsonObject(with: data) as! [String: Any]
    }
}
