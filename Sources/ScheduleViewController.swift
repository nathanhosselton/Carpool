import UIKit
import CarpoolKit

final class ScheduleViewController: UITableViewController {

    private var trips: [Trip] = []
    private var legs: [Leg] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Schedule"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(onAdd))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "a")

        go()
    }

    @objc func onAdd() {
        navigationController?.pushViewController(CreateTripViewController(), animated: true)
    }

    private func go() {
        API.fetchTripsOnce { trips in
            self.trips = trips
            self.legs = zip(trips.map{ $0.pickUp }, trips.map{ $0.dropOff }).flatMap{ [$0, $1] }
            self.tableView.reloadData()
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return legs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "a", for: indexPath)

        cell.textLabel?.attributedText = trip(for: indexPath).event.prettyDescription
        cell.backgroundColor = legs[indexPath.row].isClaimed ? .clear : .red

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let eventDetailVC = TripDetailViewController(event: trip(for: indexPath).event, leg: legs[indexPath.row])
        navigationController?.pushViewController(eventDetailVC, animated: true)
    }

    private func trip(for indexPath: IndexPath) -> Trip {
        return trips[Int(floor(Double(indexPath.row) / 2.0))]
    }

}
