import UIKit
import CarpoolKit

class ScheduleViewController: UITableViewController {

    var trips: [Trip] = []
    var legs: [Leg] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Schedule"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "a")

        go()
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

    private func trip(for indexPath: IndexPath) -> Trip {
        return trips[Int(floor(Double(indexPath.row) / 2.0))]
    }

}



extension Event {
    var prettyDescription: NSAttributedString {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return NSMutableAttributedString().bold(description).normal(" at ").bold(formatter.string(from: time))
    }
}
