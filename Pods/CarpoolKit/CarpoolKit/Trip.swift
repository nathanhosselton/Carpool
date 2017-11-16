import FirebaseCommunity
import CoreLocation
import PromiseKit

public struct Trip: Codable, Keyed {
    var key: String!
    public let event: Event

    /// the leg for dropping off children at the event
    public let dropOff: Leg?

    /// the leg for picking up children from the event
    public let pickUp: Leg?

    enum CodingKeys: String, CodingKey {
        case key, event, pickUp, dropOff, comments, repeats
        case _children = "children"
    }

    public var children: [Child] {
        return _children ?? []
    }
    let _children: [Child]?

    public let comments: [Comment]
    public let repeats: Bool
}

public extension API {
    /// call this if you need to stop previous observers firing
    public static func unobserveAllTrips() {
        Database.database().reference().child("trips").removeAllObservers()
    }

    /// returns all trips, continuously
    public static func observeTrips(sender: UIViewController, completion: @escaping (Result<[Trip]>) -> Void) {
        firstly {
            auth()
        }.then { () -> Void in
            let reaper = Reaper()
            reaper.ref = Database.database().reference().child("trips")
            reaper.observer = reaper.ref.observe(.value) { snapshot in
                firstly {
                    when(resolved: snapshot.children.map{ Trip.make(with: $0 as! DataSnapshot) })
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
                firstly {
                    fetchCurrentUser()
                }.then { user in
                    observer(.success(trips.filter{ $0.event.owner == user }))
                }.catch {
                    observer(.failure($0))
                }
            case .failure(let error):
                observer(.failure(error))
            }
        }
    }

    public static func observeMyTripCalendar(sender: UIViewController, observer: @escaping (Result<TripCalendar>) -> Void) {
        API.observeMyTrips(sender: sender) { result in
            switch result {
            case .success(let trips):
                observer(.success(TripCalendar(trips: trips)))
            case .failure(let error):
                observer(.failure(error))
            }
        }
    }

    public static func observeTheTripCalendarOfMyFriends(sender: UIViewController, observer: @escaping (Result<TripCalendar>) -> Void) {
        API.observeTheTripsOfMyFriends(sender: sender) { result in
            switch result {
            case .success(let trips):
                observer(.success(TripCalendar(trips: trips)))
            case .failure(let error):
                observer(.failure(error))
            }
        }
    }

    /// One week's worth of trips
    public struct TripCalendar {
        public struct DailySchedule {
            public let trips: [Trip]
            public let prettyName: String
            public let date: Date
        }

        /**
             dailySchedule(forWeekdayOffsetFromToday: 0)  //today
             dailySchedule(forWeekdayOffsetFromToday: 1)  //tomorrow
         */
        public func dailySchedule(forWeekdayOffsetFromToday dayOffset: Int) -> DailySchedule {
            let low = today + TimeInterval(dayOffset * 60 * 60 * 24)
            let high = low + TimeInterval(60 * 60 * 24)
            let trips = self.trips.filter { $0.shouldShow(from: low, to: high) }.sorted().reversed()

            let date = today + TimeInterval(dayOffset * 60 * 60 * 24)

            let df = DateFormatter()
            df.dateFormat = "EEEE, MMM d"
            let prettyName = df.string(from: date)

            return DailySchedule(trips: Array(trips), prettyName: prettyName, date: date)
        }

        public let trips: [Trip]
        public let today = Calendar.current.startOfDay(for: Date())
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
        let reaper = Reaper()
        reaper.ref = Database.database().reference().child("trips").child(trip.key)
        reaper.observer = reaper.ref.observe(.value) { snapshot in
            firstly {
                Trip.make(with: snapshot)
            }.then {
                observer(.success($0))
            }.catch {
                observer(.failure($0))
            }
        }
        sender.view.addSubview(reaper)
    }

    ///This is the `Promise` returning variant of this function.
    ///Use the original `createTrip(eventDescription:eventTime:eventLocation:completion:)` unless you intend to use Promises.
    public static func createTrip(eventDescription desc: String, eventTime time: Date, eventLocation location: CLLocation?) -> Promise<Trip> {
        guard !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Promise(error: Error.emptyDescription)
        }

        return firstly {
            fetchCurrentUser()
        }.then { user -> Trip in
            guard let fbuser = Auth.auth().currentUser else {
                throw Error.notAuthorized
            }
            guard user.name?.chuzzled() != nil, user.name != "Anonymous Parent" else {
                throw Error.anonymousUsersCannotCreateTrips
            }

            guard let geohash = (location.flatMap{ Geohash(location: $0) })?.value else {
                throw Error.locationInvalid
            }

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

            let event = Event(key: eventRef.key, description: desc, owner: user, time: time, endTime: nil, geohash: geohash)
            return Trip(key: tripRef.key, event: event, dropOff: Leg(driver: user), pickUp: nil, _children: [], comments: [], repeats: false)
        }
    }

    public static func mark(trip: Trip, repeating: Bool) {
        Database.database().reference().child("trips").child(trip.key).child("repeats").setValue(repeating)
    }

    /// claims the initial leg by the current user, so pickUp leg is UNCLAIMED
    public static func createTrip(eventDescription desc: String, eventTime time: Date, eventLocation location: CLLocation?, completion: @escaping (Result<Trip>) -> Void) {
        createTrip(eventDescription: desc, eventTime: time, eventLocation: location).then {
            completion(.success($0))
        }.catch {
            completion(.failure($0))
        }
    }

    public static func add(child: Child, to trip: Trip) throws {
        Database.database().reference().child("trips").child(trip.key).child("children").updateChildValues([
            child.key: try child.json()
        ])
    }

    /// This is the `Promise` returning variant of this function.
    /// Use the original `claimPickUp(trip:completion:)` unless you intend to use Promises.
    public static func claimPickUp(trip: Trip) -> Promise<Void> {
        return claim("pickUp", claim: true, trip: trip)
    }

    /// if there is no error, completes with nil
    public static func claimPickUp(trip: Trip, completion: @escaping (Swift.Error?) -> Void) {
        claim("pickUp", claim: true, trip: trip, completion: completion)
    }

    /// This is the `Promise` returning variant of this function.
    /// Use the original `claimDropOff(trip:completion:)` unless you intend to use Promises.
    public static func claimDropOff(trip: Trip) -> Promise<Void> {
        return claim("dropOff", claim: true, trip: trip)
    }

    /// if there is no error, completes with nil
    public static func claimDropOff(trip: Trip, completion: @escaping (Swift.Error?) -> Void) {
        claim("dropOff", claim: true, trip: trip, completion: completion)
    }

    /// This is the `Promise` returning variant of this function.
    /// Use the original `unclaimPickUp(trip:completion:)` unless you intend to use Promises.
    public static func unclaimPickUp(trip: Trip) -> Promise<Void> {
        return claim("pickUp", claim: false, trip: trip)
    }

    /// if there is no error, completes with nil
    public static func unclaimPickUp(trip: Trip, completion: @escaping (Swift.Error?) -> Void) {
        claim("pickUp", claim: false, trip: trip, completion: completion)
    }

    /// This is the `Promise` returning variant of this function.
    /// Use the original `unclaimDropOff(trip:completion:)` unless you intend to use Promises.
    public static func unclaimDropOff(trip: Trip) -> Promise<Void> {
        return claim("dropOff", claim: false, trip: trip)
    }

    /// if there is no error, completes with nil
    public static func unclaimDropOff(trip: Trip, completion: @escaping (Swift.Error?) -> Void) {
        claim("dropOff", claim: false, trip: trip, completion: completion)
    }

    static func claim(_ key: String, claim: Bool, trip: Trip) -> Promise<Void> {
        return firstly {
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
        }
    }

    static func claim(_ key: String, claim cc: Bool, trip: Trip, completion: @escaping (Swift.Error?) -> Void) {
        claim(key, claim: cc, trip: trip).then {
            completion(nil)
        }.catch {
            completion($0)
        }
    }

    public static func delete(trip: Trip) throws {
        guard trip.event.owner.key == Auth.auth().currentUser?.uid else {
            throw Error.notYourTripToDelete
        }
        Database.database().reference().child("trips").child(trip.key).removeValue()
    }
}

extension Trip: Equatable {
    public static func ==(lhs: Trip, rhs: Trip) -> Bool {
        return lhs.key == rhs.key
    }
}

extension Trip: Comparable {
    public static func <(lhs: Trip, rhs: Trip) -> Bool {
        return lhs.event.time > rhs.event.time
    }
}

extension Trip: Hashable {
    public var hashValue: Int {
        return key.hashValue
    }
}

extension Trip {
    static func make(with snapshot: DataSnapshot) -> Promise<Trip> {
        do {
            let key = snapshot.key
            guard let json = snapshot.value as? [String: Any] else { throw API.Error.decode}

            func getLeg(key: String) -> Promise<User?> {
                guard let json = json[key] as? [String: String] else { return Promise(value: nil) }
                guard let item = json.first else { return Promise(value: nil) }
                return API.fetchUser(id: item.key).then(on: zalgo){ $0 }
            }

            let children: [Child]? = try? snapshot.childSnapshot(forPath: "children").array()
            let dropOff = getLeg(key: "dropOff")
            let pickUp = getLeg(key: "pickUp")
            let event = Event.make(key: "event", json: json)
            let comments = snapshot.childSnapshot(forPath: "comments").children.flatMap {
                Comment.make(id: ($0 as! DataSnapshot).key)
            }
            let repeats = snapshot.childSnapshot(forPath: "repeats").value as? Bool ?? false

            return firstly {
                when(fulfilled: dropOff, pickUp, event, when(fulfilled: comments))
            }.then { dropOff, pickUp, event, comments in
                Trip(key: key, event: event, dropOff: dropOff.map(Leg.init), pickUp: pickUp.map(Leg.init), _children: children, comments: comments, repeats: repeats)
            }
        } catch {
            return Promise(error: error)
        }
    }

    func shouldShow(from low: Date, to high: Date) -> Bool {
        if event.time >= low && event.time <= high {
            return true
        }
        guard repeats else { return false }

        var cc1 = Calendar.current.dateComponents(in: .current, from: low)
        var cc2 = Calendar.current.dateComponents(in: .current, from: event.time)
        cc2.month = cc1.month
        cc2.weekday = cc1.weekday
        cc2.day = nil
        cc2.weekOfMonth = cc1.weekOfMonth

        guard let modifiedEventDate = cc2.date else {
            print("TELL MAX TO FIX HIS SHIT. TO GET ALL HIS SHIT TOGETHER. TO ASSEMBLE ALL HIS SHIT TOGETHER AND TO FIX IT")
            return false
        }
        return modifiedEventDate >= low && modifiedEventDate <= high
    }
}

extension Trip: CustomDebugStringConvertible {
    public var debugDescription: String {
        return key
    }
}

public typealias TripCalendar = API.TripCalendar
public typealias DailySchedule = API.TripCalendar.DailySchedule
