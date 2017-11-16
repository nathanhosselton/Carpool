import UIKit
import CarpoolKit

final class ScheduleViewController: UITableViewController {
    private let filterControl = UISegmentedControl(.byhand, "My Trips", "Friend Trips")

    private var mySchedule: [API.TripCalendar.DailySchedule] = []
    private var friendTrips: [Trip] = []

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

        fetchTrips()
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

    private func fetchTrips() {
        API.observeMyTripCalendar(sender: self) { (result) in
            switch result {
            case .success(let calendar):
                self.mySchedule = (0...6).map(calendar.dailySchedule)
                if self.filterControl.selectedSegmentIndex == 0 { self.tableView.reloadData() }
            case .failure(let error):
                print(error)
            }
        }

        API.observeTheTripsOfMyFriends(sender: self) { result in
            switch result {
            case .success(let trips):
                self.friendTrips = trips
                if self.filterControl.selectedSegmentIndex == 1 { self.tableView.reloadData() }
            case .failure(let error):
                print(error)
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return filterControl.selectedSegmentIndex == 0 ? mySchedule.count : 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard filterControl.selectedSegmentIndex == 0 else { return "Upcoming trips from friends" }
        let day = mySchedule[section]
        return day.trips.isEmpty ? nil : day.prettyName
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return onscreenTrips(for: section).count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.reuseId, for: indexPath)
        cell.textLabel?.attributedText = onscreenTrips(for: indexPath.section)[indexPath.row].event.prettyDescription
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tripDetailVC = TripDetailViewController(trip: onscreenTrips(for: indexPath.section)[indexPath.row])
        navigationController?.pushViewController(tripDetailVC, animated: true)
    }

    private func onscreenTrips(for section: Int) -> [Trip] {
        switch filterControl.selectedSegmentIndex {
        case 0: return mySchedule[section].trips
        case 1: return friendTrips
        default: fatalError()
        }
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
