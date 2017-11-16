import FirebaseCommunity
import PromiseKit

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

public extension API {
    static func fetchCurrentUser(completion: @escaping (Result<User>) -> Void) {
        fetchCurrentUser().then {
            completion(.success($0))
        }.catch {
            completion(.failure($0))
        }
    }

    /// This is the `Promise` returning variant of this function.
    /// Use the original `fetchCurrentUser(completion:)` unless you intend to use Promises.
    static func fetchCurrentUser() -> Promise<User> {
        return firstly {
            auth()
        }.then { () -> Promise<User> in
            guard let uid = Auth.auth().currentUser?.uid else {
                throw Error.notAuthorized
            }
            return Promise { fulfill, reject in
                fetchUser(id: uid, completion: { result in
                    switch result {
                    case .success(let user):
                        fulfill(user)
                    case .failure(let error):
                        reject(error)
                    }
                })
            }
        }
    }

    /// This is the `Promise` returning variant of this function.
    /// Use the original `addChild(name:completion:)` unless you intend to use Promises.
    static func addChild(name: String) -> Promise<Child> {
        guard name.chuzzled() != nil else { return Promise(error: Error.noChildName) }

        return firstly {
            fetchCurrentUser()
        }.then { user -> Child in
            if let child = user.children.first(where: { $0.name == name }) {
                return child
            } else {
                let ref1 = Database.database().reference().child("children").childByAutoId()
                ref1.setValue(["name": name])
                Database.database().reference().child("users").child(user.key).child("children").updateChildValues([
                    ref1.key: name
                ])
                return Child(key: ref1.key, name: name)
            }
        }
    }

    static func addChildren(names: [String], completion: Result<[Child]>) {
        firstly {
            fetchCurrentUser()
        }.then { user -> [Child] in
            let existingNames = user.children.map{ $0.name }
            let names = names.flatMap{ $0.chuzzled() }.filter{ !existingNames.contains($0) }
            let refs = names.map { name -> (key: String, name: String) in
                let ref = Database.database().reference().child("children").childByAutoId()
                ref.setValue(["name": name])
                return (ref.key, name)
            }
            Database.database().reference().child("users").child(user.key).child("children").updateChildValues(
                refs.reduce(into: [:]){ $0[$1.key] = $1.name }
            )
            return refs.map{ Child(key: $0.0, name: $0.1) }
        }
    }


    /// adds children to the logged in user
    /// if a child already exists with that name, returns the existing child
    static func addChild(name: String, completion: @escaping (Result<Child>) -> Void) {
        addChild(name: name).then {
            completion(.success($0))
        }.catch {
            completion(.failure($0))
        }
    }

    /// This is the `Promise` returning variant of this function.
    /// Use the original `search(forUsersWithName:completion:)` unless you intend to use Promises.
    static func search(forUsersWithName query: String) -> Promise<[User]> {
        latestQuery = query
        let cancelIfNecessary = {
            if query != latestQuery {
                throw NSError(domain: NSURLErrorDomain, code: URLError.cancelled.rawValue)
            }
        }

        //FIXME will not scale
        let query = query.lowercased()
        return firstly {
            Database.fetch(path: "users")
        }.then(on: .global()) { snapshot -> [User] in
            try cancelIfNecessary()

            return snapshot.children.flatMap { snapshot in
                do {
                    let snapshot = snapshot as! DataSnapshot
                    return User(
                        key: snapshot.key,
                        name: try snapshot.childSnapshot(forPath: "name").string(),
                        _children: try snapshot.childSnapshot(forPath: "children").children.map { snapshot in
                            let snapshot = snapshot as! DataSnapshot
                            return Child(key: snapshot.key, name: try snapshot.string())
                        })
                } catch {
                    return nil
                }
            }.filter {
                guard let parts = $0.name?.lowercased().split(separator: " ") else {
                    return false
                }
                for part in parts { if part.contains(query) {
                    return true
                }}
                return false
            }
        }.then { users -> [User] in
            try cancelIfNecessary()
            return users
        }.recover { error -> [User] in
            try cancelIfNecessary()
            throw error
        }
    }

    /**
      Search for users in the system. Automatically cancels previous searches if you make new ones.
      This means it is safe to use “as-you-type”.
     */
    static func search(forUsersWithName query: String, completion: @escaping (Result<[User]>) -> Void) {
        search(forUsersWithName: query).then {
            completion(.success($0))
        }.catch {
            completion(.failure($0))
        }
    }

    static func add(friend: User) {
        guard let uid = Auth.auth().currentUser?.uid else { return }  //TODO error handling
        Database.database().reference().child("users").child(uid).child("friends").updateChildValues([
            friend.key: friend.name ?? "Anonymous Parent"
        ])
    }

    static func remove(friend: User) {
        guard let uid = Auth.auth().currentUser?.uid else { return }  //TODO error handling
        Database.database().reference().child("users").child(uid).child("friends").child(friend.key).removeValue()
    }

    static func observeFriends(sender: UIViewController, observer: @escaping (Result<[User]>) -> Void) {
        firstly {
            fetchCurrentUser()
        }.then { user -> Void in
            let reaper = Reaper()
            reaper.ref = Database.database().reference().child("users").child(user.key).child("friends")
            reaper.observer = reaper.ref.observe(.value) { snapshot in
                when(fulfilled: snapshot.children.map {
                    fetchUser(id: ($0 as! DataSnapshot).key)
                }).then {
                    observer(.success($0))
                }.catch {
                    observer(.failure($0))
                }
            }
            sender.view.addSubview(reaper)
        }.catch {
            observer(.failure($0))
        }
    }
}

extension API {
    static func fetchUser(id uid: String, completion: @escaping (Result<User>) -> Void) {
        firstly {
            fetchUser(id: uid)
            }.then {
                completion(.success($0))
            }.catch {
                completion(.failure($0))
        }
    }

    static func fetchUser(id uid: String) -> Promise<User> {
        return firstly {
            auth()
            }.then {
                Database.fetch(path: "users", uid)
            }.then { snap -> Promise<User> in
                let name = (try? snap.childSnapshot(forPath: "name").string()) ?? "Anonymous Parent"

                return when(fulfilled: snap.childSnapshot(forPath: "children").keys.map { key in
                    Database.fetch(path: "children", key).then {
                        try $0.value(key: key) as Child
                    }
                }).then {
                    User(key: uid, name: name, _children: $0)
                }
        }
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

private var latestQuery: String?
