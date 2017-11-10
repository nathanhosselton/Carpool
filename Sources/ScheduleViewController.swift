import UIKit
import CarpoolKit

final class ScheduleViewController: UITableViewController {
    let filterControl = UISegmentedControl("My Trips", "All Trips")

    typealias ContextualLeg = (leg: Leg, trip: Trip)

    private var myLegs: [ContextualLeg] = []
    private var allLegs: [ContextualLeg] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Schedule"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(onAdd))

        tableView.register(Cell.self, forCellReuseIdentifier: Cell.reuseId)
        tableView.tableHeaderView = filterControl

        filterControl.addTarget(self, action: #selector(onFilterChanged), for: .valueChanged)

        go()
    }

    @objc func onAdd() {
        navigationController?.pushViewController(CreateTripViewController(), animated: true)
    }

    @objc func onFilterChanged() {
        tableView.reloadData()
    }

    private func go() {
        //FIXME: Use PromiseKit.when

        API.observeMyTrips { (result) in
            switch result {
            case .success(let trips):
                self.myLegs = trips.flatMap{ trip in [trip.dropOff, trip.pickUp].flatMap{ $0 }.map{ ($0, trip) } }
                self.tableView.reloadData()
            case .failure(let error):
                print(error)
            }
        }

        API.observeTrips { result in
            switch result {
            case .success(let trips):
                self.allLegs = trips.flatMap{ trip in [trip.dropOff, trip.pickUp].flatMap{ $0 }.map{ ($0, trip) } }
            case .failure(let error):
                print(error)
            }
        }
    }

    private var onscreenLegs: [ContextualLeg] {
        switch filterControl.selectedSegmentIndex {
        case 0: return myLegs
        case 1: return allLegs
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
