import CoreLocation

public enum API {

    public static var isAuthorized: Bool {
        return true
    }

    public static func fetchTripsOnce(completion: @escaping ([Trip]) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {

            let trips = fakeEvents.enumerated().map {
                Trip(id: "\($0.0)",
                    event: $0.1,
                    pickUp: Leg(id: UUID().uuidString, driver: fakeUsers.maybe),
                    dropOff: Leg(id: UUID().uuidString, driver: fakeUsers.maybe))
            }

            completion(trips)
        }
    }

    public static func update(user: User, name: String) {
        UserDefaults.standard.set(name, forKey: "username")
    }
}

private let fakeUsers = [
    User(id: "0", name: "Akiva", phone: 0),
    User(id: "1", name: "Akash", phone: 0),
    User(id: "2", name: "Naina", phone: 0),
    User(id: "3", name: "Riyazh", phone: 0),
    User(id: "4", name: "Shannon", phone: 0),
    User(id: "5", name: "Nathan", phone: 0),
    User(id: "6", name: "Aleshia", phone: 0),
    User(id: "7", name: "Max", phone: 0),
    User(id: "8", name: "Ernesto", phone: 0),
    User(id: "9", name: "Jess", phone: 0),
    User(id: "10", name: "Josh", phone: 0),
    User(id: "11", name: "Laurie", phone: 0),
    User(id: "12", name: "Alex", phone: 0),
    User(id: "13", name: "Gary", phone: 0),
    User.current
]

private let fakeEvents = [
    Event(id: "0", description: "Take Johnny to band-camp", time: Date(), location: CLLocation()),
    Event(id: "1", description: "Visit Grandma in hospital", time: Date(), location: CLLocation()),
    Event(id: "2", description: "Take Arya to faceless men HQ", time: Date(), location: CLLocation()),
    Event(id: "3", description: "Dentist Appt. for Bill", time: Date(), location: CLLocation()),
    Event(id: "4", description: "Drop off Will at The-Upside-Down", time: Date(), location: CLLocation()),
]


extension Array {
    public var sample: Element {
        let n = Int(arc4random_uniform(UInt32(count)))
        return self[n]
    }

    var maybe: Element? {
        if arc4random() % 3 == 0 {
            return nil
        } else {
            return sample
        }
    }
}
