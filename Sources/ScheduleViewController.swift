import UIKit
import CarpoolKit

final class ScheduleViewController: UITableViewController {

    private var legs: [(leg: Leg, trip: Trip)] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Schedule"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(onAdd))
        tableView.register(Cell.self, forCellReuseIdentifier: Cell.reuseId)

        go()
    }

    @objc func onAdd() {
        navigationController?.pushViewController(CreateTripViewController(), animated: true)
    }

    private func go() {
        API.observeTrips { result in
            switch result {
            case .success(let trips):

                self.legs.removeAll()
                for trip in trips {
                    if let dropOff = trip.dropOff {
                        self.legs.append((dropOff, trip))
                    }
                    if let pickup = trip.pickUp {
                        self.legs.append((pickup, trip))
                    }
                }

                //FIXME: Produces [(Leg?, Trip)] cant figure out how to filter nil legs without needing a cast
//                let foo = trips.map{ (($0.dropOff, $0), ($0.pickUp, $0)) }.flatMap{ [$0.0, $0.1] }

                self.tableView.reloadData()
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return legs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.reuseId, for: indexPath)
        cell.textLabel?.attributedText = legs[indexPath.row].trip.event.prettyDescription
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let (leg, trip) = legs[indexPath.row]
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
