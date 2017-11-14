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

        go()
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

    private func go() {
        API.observeMyTrips(sender: self) { (result) in
            switch result {
            case .success(let trips):
                self.myLegs = trips.flatMap{ trip in [trip.dropOff, trip.pickUp].flatMap{ $0 }.map{ ($0, trip) } }
                if self.filterControl.selectedSegmentIndex == 0 { self.tableView.reloadData() }
            case .failure(let error):
                print(error)
            }
        }

        API.observeTheTripsOfMyFriends(sender: self) { (result) in
            switch result {
            case .success(let trips):
                self.friendLegs = trips.flatMap{ trip in [trip.dropOff, trip.pickUp].flatMap{ $0 }.map{ ($0, trip) } }
                if self.filterControl.selectedSegmentIndex == 1 { self.tableView.reloadData() }
            case .failure(let error):
                print(error)
            }
        }
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
