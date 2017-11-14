import UIKit
import CarpoolKit

final class ScheduleViewController: UITableViewController {
    private let filterControl = UISegmentedControl(.byhand, "My Trips", "Friend Trips")

    typealias ContextualLeg = (leg: Leg, trip: Trip)

    private var myLegs: [ContextualLeg] = []
    private var friendLegs: [ContextualLeg] = []

    private var addFriend: UIBarButtonItem {
        return navigationItem.leftBarButtonItem!
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Schedule"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Add Friend", style: .plain, target: self, action: #selector(onAddFriend))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Create Trip", style: .plain, target: self, action: #selector(onCreateTrip))

        tableView.register(Cell.self, forCellReuseIdentifier: Cell.reuseId)
        tableView.tableHeaderView = filterControl

        addFriend.isEnabled = false
        addFriend.tintColor = .clear

        filterControl.addTarget(self, action: #selector(onFilterChanged), for: .valueChanged)

        API.fetchCurrentUser().then(execute: fetchLegs)
    }

    @objc func onAddFriend() {
        navigationController?.pushViewController(AddFriendViewController(), animated: true)
    }

    @objc func onCreateTrip() {
        navigationController?.pushViewController(CreateTripViewController(), animated: true)
    }

    @objc func onFilterChanged() {
        tableView.reloadData()
        addFriend.isHidden = filterControl.selectedSegmentIndex != 1
    }

    private func fetchLegs(for user: CarpoolKit.User) {
        let updateLegs: ([ContextualLeg]) -> Void = { legs in
            let refreshSection: Int

            switch legs.first {
            case .some(_, let trip) where trip.event.owner == user:
                self.myLegs = legs
                refreshSection = 0
            case .some(_, _):
                self.friendLegs = legs
                refreshSection = 1
            case .none:
                //TODO: Let the user know they should create some trips or add some friends
                refreshSection = -1
            }

            if self.filterControl.selectedSegmentIndex == refreshSection { self.tableView.reloadData() }
        }

        let refresh: (Result<[Trip]>) -> Void = { result in
            switch result {
            case .success(let trips):
                let legs = trips.flatMap{ trip in [trip.dropOff, trip.pickUp].flatMap{ $0 }.map{ ($0, trip) } }
                updateLegs(legs)
            case .failure(let error):
                print(error)
            }
        }

        API.observeMyTrips(sender: self, observer: refresh)
        API.observeTheTripsOfMyFriends(sender: self, observer: refresh)
    }

    private var onscreenLegs: [ContextualLeg] {
        switch filterControl.selectedSegmentIndex {
        case 0: return myLegs
        case 1: return friendLegs
        default: fatalError()
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return onscreenLegs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.reuseId, for: indexPath)
        cell.textLabel?.attributedText = onscreenLegs[indexPath.row].trip.event.prettyDescription
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let (leg, trip) = onscreenLegs[indexPath.row]
        let eventDetailVC = TripDetailViewController(event: trip.event, leg: leg)
        navigationController?.pushViewController(eventDetailVC, animated: true)
    }

}

private final class Cell: UITableViewCell {
    static var reuseId: String {
        return String(describing: Cell.self)
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        textLabel?.numberOfLines = 0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Cell.init(coder:) has not been implemented")
    }
}
