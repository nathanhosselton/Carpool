import FirebaseCommunity
import CoreLocation
import PromiseKit

public enum API {
    public enum Error: Swift.Error {
        case notAuthorized
        case noChildNode
        case noChildNodes
        case decode
        case invalidJsonType
        case emptyDescription
        case notAString
        case notYourTripToDelete
        case anonymousUsersCannotCreateTrips
        case deprecated
        case noChildName

        /// sign-up or sign-in failed
        case signInFailed(underlyingError: Swift.Error)
    }

    static func auth() -> Promise<Void> {

        func foo() -> Promise<FirebaseCommunity.User> {
            if let foo = Auth.auth().currentUser { return Promise(value: foo) }
            return PromiseKit.wrap(Auth.auth().signInAnonymously)
        }

        return firstly {
            foo()
        }.then { fbuser in
            Database.fetch(path: "users", fbuser.uid).then {
                (fbuser.uid, $0.string(for: "name"))
            }
        }.then { uid, name -> Void in
            if name != nil { return }
            Database.database().reference().child("users").child(uid).setValue([
                "ctime": Date().timeIntervalSince1970
            ])
        }
    }

    public static func signUp(email: String, password: String, fullName: String, completion: @escaping (Result<User>) -> Void) {
        if let user = Auth.auth().currentUser {
            link(user: user, email: email, password: password, completion: completion)
            Database.database().reference().child("users").child(user.uid).updateChildValues([
                "name": fullName
            ])
        } else {
            firstly {
                PromiseKit.wrap{ Auth.auth().createUser(withEmail: email, password: password, completion: $0) }
            }.then { user in
                auth().then {
                    Database.database().reference().child("users").child(user.uid).updateChildValues([
                        "name": fullName
                    ])
                }
            }.then {
                fetchCurrentUser()
            }.then {
                completion(.success($0))
            }.catch {
                completion(.failure($0))
            }
        }
    }

    private static func link(user: FirebaseCommunity.User, email: String, password: String, completion: @escaping (Result<User>) -> Void) {
        let creds = EmailAuthProvider.credential(withEmail: email, password: password)
        user.link(with: creds, completion: { user, error in
            if user != nil {
                fetchCurrentUser().then {
                    completion(.success($0))
                }.catch {
                    completion(.failure($0))
                }
            } else if let error = error {
                completion(.failure(Error.signInFailed(underlyingError: error)))
            } else {
                completion(.failure(Error.signInFailed(underlyingError: PMKError.invalidCallingConvention)))
            }
        })
    }

    public static func signIn(email: String, password: String, completion: @escaping (Result<User>) -> Void) {
        if let user = Auth.auth().currentUser {
            link(user: user, email: email, password: password, completion: completion)
        } else {
            firstly {
                PromiseKit.wrap{ Auth.auth().signIn(withEmail: email, password: password, completion: $0) }
            }.then { _ in
                auth()
            }.then {
                fetchCurrentUser()
            }.then {
                completion(.success($0))
            }.catch {
                completion(.failure($0))
            }
        }
    }

    /// returns all trips, continuously
    public static func observeTrips(sender: UIViewController, completion: @escaping (Result<[Trip]>) -> Void) {
        firstly {
            auth()
        }.then { () -> Void in
            let reaper = Lifetime()
            reaper.ref = Database.database().reference().child("trips")
            reaper.observer = reaper.ref.observe(.value) { snapshot in
                guard let foo = snapshot.value as? [String: [String: Any]] else {
                    return completion(.failure(API.Error.noChildNodes))
                }
                firstly {
                    when(resolved: foo.map{ Trip.make(key: $0, json: $1) })
                }.then { results -> Void in
                    var trips: [Trip] = []
                    for case .fulfilled(let trip) in results { trips.append(trip) }
                    if trips.isEmpty && !results.isEmpty {
                        throw Error.noChildNodes
                    }
                    trips.sort()
                    completion(.success(trips))
                }.catch {
                    completion(.failure($0))
                }
            }
            sender.view.addSubview(reaper)
        }.catch {
            completion(.failure($0))
        }
    }

    /// returns all the current user's trips, continuously
    public static func observeMyTrips(sender: UIViewController, observer: @escaping (Result<[Trip]>) -> Void) {
        observeTrips(sender: sender) { result in
            switch result {
            case .success(let trips):
                fetchCurrentUser().then { user in
                    observer(.success(trips.filter{ $0.event.owner == user }))
                }.catch {
                    observer(.failure($0))
                }
            case .failure(let error):
                observer(.failure(error))
            }
        }
    }

    /// returns all the current user's friends' trips, continuously
    public static func observeTheTripsOfMyFriends(sender: UIViewController, observer: @escaping (Result<[Trip]>) -> Void) {

        var trips: [Trip] = []
        var friends: [User] = []

        func process() {
            guard trips.count > 0, friends.count > 0 else { return }
            observer(.success(trips.filter{ friends.contains($0.event.owner) }))
        }

        observeTrips(sender: sender) { result in
            switch result {
            case .success(let _trips):
                trips = _trips
                process()
            case .failure(let error):
                observer(.failure(error))
            }
        }

        observeFriends(sender: sender) { result in
            switch result {
            case .success(let _friends):
                friends = _friends
                process()
            case .failure(let error):
                observer(.failure(error))
            }
        }
    }

    /// observe changes to the Trip, so if you have a trip
    /// object on your VC you will want to observe it here
    /// and update that property with the new value from the observer callback
    public static func observe(trip: Trip, sender: UIViewController, observer: @escaping (Result<Trip>) -> Void) {
        let reaper = Lifetime()
        reaper.ref = Database.database().reference().child("trips").child(trip.key)
        reaper.observer = reaper.ref.observe(.value) { snapshot in
            do {
                guard let json = snapshot.value as? [String: Any] else { throw Error.noChildNode }
                firstly {
                    Trip.make(key: trip.key, json: json)
                }.then {
                    observer(.success($0))
                }.catch {
                    observer(.failure($0))
                }
            } catch {
                observer(.failure(error))
            }
        }

        sender.view.addSubview(reaper)
    }

    /// claims the initial leg by the current user, so pickUp leg is UNCLAIMED
    public static func createTrip(eventDescription desc: String, eventTime time: Date, eventLocation location: CLLocation?, completion: @escaping (Result<Trip>) -> Void) {
        guard !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return DispatchQueue.main.async {
                completion(.failure(Error.emptyDescription))
            }
        }

        firstly {
            fetchCurrentUser()
        }.then { user -> Void in
            guard let fbuser = Auth.auth().currentUser else {
                throw Error.notAuthorized
            }
            guard user.name?.chuzzled() != nil, user.name != "Anonymous Parent" else {
                throw Error.anonymousUsersCannotCreateTrips
            }

            let geohash = location.flatMap{ Geohash(location: $0) }?.value

            var eventDict: [String: Any] = [
                "description": desc,
                "time": time.timeIntervalSince1970,
                "owner": [fbuser.uid: user.name!]
            ]
            eventDict["geohash"] = geohash
            let eventRef = Database.database().reference().child("events").childByAutoId()

            let tripRef = Database.database().reference().child("trips").childByAutoId()
            tripRef.setValue([
                "dropOff": [fbuser.uid: user.name!],
                "event": [eventRef.key: eventDict],
                "owner": [fbuser.uid: user.name!]
            ])

            var eventDict2 = eventDict
            eventDict2["trips"] = [tripRef.key: true]
            eventRef.setValue(eventDict2)

            let event = Event(key: eventRef.key, description: desc, owner: user, time: time, endTime: nil, location: geohash)
            let trip = Trip(key: tripRef.key, event: event, dropOff: Leg(driver: user), pickUp: nil, _children: [])
            completion(.success(trip))
        }.catch {
            completion(.failure($0))
        }
    }

    public static func add(child: Child, to trip: Trip) throws {
        Database.database().reference().child("trips").child(trip.key).child("children").updateChildValues([
            child.key: try child.json()
        ])
    }

    public static func fetchCurrentUser(completion: @escaping (Result<User>) -> Void) {
        fetchCurrentUser().then {
            completion(.success($0))
        }.catch {
            completion(.failure($0))
        }
    }

    public static func fetchCurrentUser() -> Promise<User> {
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

    static func fetchUser(id uid: String, completion: @escaping (Result<User>) -> Void) {
        firstly {
            fetchUser(id: uid)
        }.then {
            completion(.success($0))
        }.catch {
            completion(.failure($0))
        }
    }

    /// if there is no error, completes with nil
    public static func claimPickUp(trip: Trip, completion: @escaping (Swift.Error?) -> Void) {
        claim("pickUp", claim: true, trip: trip, completion: completion)
    }

    /// if there is no error, completes with nil
    public static func claimDropOff(trip: Trip, completion: @escaping (Swift.Error?) -> Void) {
        claim("dropOff", claim: true, trip: trip, completion: completion)
    }

    /// if there is no error, completes with nil
    public static func unclaimPickUp(trip: Trip, completion: @escaping (Swift.Error?) -> Void) {
        claim("pickUp", claim: false, trip: trip, completion: completion)
    }

    /// if there is no error, completes with nil
    public static func unclaimDropOff(trip: Trip, completion: @escaping (Swift.Error?) -> Void) {
        claim("dropOff", claim: false, trip: trip, completion: completion)
    }

    static func claim(_ key: String, claim: Bool, trip: Trip, completion: @escaping (Swift.Error?) -> Void) {
        firstly {
            fetchCurrentUser()
        }.then { user -> Void in
            let ref = Database.database().reference().child("trips").child(trip.key).child(key)
            if claim {
                ref.updateChildValues([
                    user.key: user.name ?? "Anonymous Parent"
                ])
            } else {
                ref.removeValue()
            }
            completion(nil)
        }.catch {
            completion($0)
        }
    }

    /// you can still access data as an anonymous user, but you cannot create events
    public static var isCurrentUserAnonymous: Bool {
        return Auth.auth().currentUser?.isAnonymous ?? true
    }

    public static func delete(trip: Trip) throws {
        guard trip.event.owner.key == Auth.auth().currentUser?.uid else {
            throw Error.notYourTripToDelete
        }
        Database.database().reference().child("trips").child(trip.key).removeValue()
    }

    /// adds children to the logged in user
    /// if a child already exists with that name, returns the existing child
    public static func addChild(name: String, completion: @escaping (Result<Child>) -> Void) {

        guard name.chuzzled() != nil else {
            return DispatchQueue.main.async {
                completion(.failure(Error.noChildName))
            }
        }

        firstly {
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
        }.then {
            completion(.success($0))
        }.catch {
            completion(.failure($0))
        }
    }

    public static func set(userFullName: String) {
        guard let user = Auth.auth().currentUser else { return }

        let rq = user.createProfileChangeRequest()
        rq.displayName = userFullName
        rq.commitChanges(completion: nil)

        Database.database().reference().child("users").child(user.uid).child("name").setValue(userFullName)
    }

    public static func set(endTime: Date, for event: Event) {
        let endTime = endTime.timeIntervalSince1970
        Database.database().reference().child("events").child(event.key).child("endTime").setValue(endTime)

        firstly {
            Database.fetch(path: "events", event.key, "trips")
        }.then { snapshot -> Void in
            let ref = Database.database().reference().child("trips")
            for key in snapshot.keys {
                ref.child(key).child("event").child("endTime").setValue(endTime)
            }
        }
    }

    //TODO this will not scale
    public static func search(forUsersWithName query: String, completion: @escaping (Result<[User]>) -> Void) {
        firstly {
            Database.fetch(path: "users")
        }.then(on: .global()) { users in
            try users.array().filter {
                guard let parts = $0.name?.lowercased().split(separator: " ") else {
                    return false
                }
                for part in parts { if part.contains(query) {
                    return true
                }}
                return false
            }
        }.then {
            completion(.success($0))
        }.catch {
            completion(.failure($0))
        }
    }

    public static func add(friend: User) {
        guard let uid = Auth.auth().currentUser?.uid else { return }  //TODO error handling
        Database.database().reference().child("users").child(uid).child("friends").updateChildValues([
            friend.key: friend.name ?? "Anonymous Parent"
        ])
    }

    public static func remove(friend: User) {
        guard let uid = Auth.auth().currentUser?.uid else { return }  //TODO error handling
        Database.database().reference().child("users").child(uid).child("friends").child(friend.key).removeValue()
    }

    public static func observeFriends(sender: UIViewController, observer: @escaping (Result<[User]>) -> Void) {
        firstly {
            fetchCurrentUser()
        }.then { user -> Void in
            let reaper = Lifetime()
            reaper.ref = Database.database().reference().child("users").child(user.key).child("friends")
            reaper.observer = reaper.ref.observe(.value) { snapshot in
                do {
                    observer(.success(try snapshot.array()))
                } catch {
                    observer(.failure(error))
                }
            }
            sender.view.addSubview(reaper)
        }.catch {
            observer(.failure($0))
        }
    }
}
