import FirebaseCommunity
import PromiseKit

extension DataSnapshot {
    func value<T: Decodable & Keyed>(key: String) throws -> T {
        guard let value = self.value else { throw API.Error.noChild }
        try checkIsValidJsonType(value)
        let data = try JSONSerialization.data(withJSONObject: value)
        var foo: T = try JSONDecoder().decode(T.self, from: data)
        foo.key = key
        return foo
    }

    func array<T: Decodable & Keyed>() throws -> [T] {
        guard let rawValues = self.value else { return [] }  // nothing there yet, which means empty array
        if rawValues is NSNull { return [] }  // nothing there yet, which means empty array
        guard let values = rawValues as? [String: Any] else { throw API.Error.noChildren }

        return try values.map {
            try checkIsValidJsonType($0.value)
            let data = try JSONSerialization.data(withJSONObject: $0.value)
            var foo: T = try JSONDecoder().decode(T.self, from: data)
            foo.key = $0.key
            return foo
        }
    }

    func string() throws -> String {
        guard let string = value as? String else { throw API.Error.notAString }
        return string
    }

    func string(for key: String) -> String? {
        guard let values = self.value as? [String: Any] else { return nil }
        return values[key] as? String
    }

    var keys: [String] {
        if let keys = (value as? [String: Any])?.keys {
            return Array(keys)
        } else {
            return []
        }
    }
}

extension Database {
    static func fetch(path keys: String...) -> Promise<DataSnapshot> {
        return Promise<DataSnapshot> { fulfill, reject in
            var ref = database().reference()
            for key in keys { ref = ref.child(key) }
            ref.observeSingleEvent(of: .value) { snapshot in
                fulfill(snapshot)
            }
        }
    }
}
