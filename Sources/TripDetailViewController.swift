import UIKit
import CarpoolKit

private let margin: CGFloat = 8

final class TripDetailViewController: UIViewController {
    private var labels: UIStackView!

    private let event: Event
    private let leg: Leg

    init(event: Event, leg: Leg) {
        self.event = event
        self.leg = leg
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError(#file + ": init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Details"
        view.backgroundColor = .white
        edgesForExtendedLayout = []

        labels = {
            let rv = UIStackView(arrangedSubviews: [
                UILabel(event.prettyDescription),
                UILabel("Driver: " + (leg.driver.name ?? "Anonymous User"))
            ])
            rv.distribution = .fillProportionally
            rv.axis = .vertical
            return rv
        }()

        view.addSubview(labels)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        labels.frame = CGRect(x: margin, y: margin, width: width - margin * 2, height: 200)
    }

}

private extension UILabel {
    convenience init(_ text: String) {
        self.init(NSMutableAttributedString().normal(text))
    }

    convenience init(_ attrText: NSAttributedString) {
        self.init(frame: .zero)
        attributedText = attrText
        textAlignment = .center
    }
}
