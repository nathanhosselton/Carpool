import UIKit
import CarpoolKit

private let margin = 8.f

final class TripDetailViewController: UIViewController {
    private let labels: UIStackView

    private let event: Event
    private let leg: Leg

    init(event: Event, leg: Leg) {
        self.event = event
        self.leg = leg
        self.labels = UIStackView(arrangedSubviews: [
            UILabel(event.prettyDescription, .center),
            UILabel("Driver: " + (leg.driver.name ?? "Anonymous User"), .center)
        ])
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("TripDetailViewController.init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Details"
        view.backgroundColor = .white
        edgesForExtendedLayout = []

        labels.distribution = .fillProportionally
        labels.axis = .vertical
        labels.subviews.forEach { ($0 as? UILabel)?.numberOfLines = 0 }

        view.addSubview(labels)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        labels.frame = CGRect(x: margin, y: margin, width: width - margin * 2, height: 200)
    }

}
