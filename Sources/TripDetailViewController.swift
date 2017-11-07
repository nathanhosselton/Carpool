import UIKit
import CarpoolKit

private let margin: CGFloat = 8

final class TripDetailViewController: UIViewController {
    private var labels: UIStackView!
    private var becomeDriverButton: UIButton!

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
                UILabel("Driver: \(leg.driver?.name ?? "None assigned")"),
                UILabel("Driver 📞: \(leg.driver?.prettyPhone ?? "None assigned")")
            ])
            rv.distribution = .fillProportionally
            rv.axis = .vertical
            return rv
        }()

        becomeDriverButton = {
            let rv = UIButton(type: .roundedRect)
            rv.setTitle("Assign yourself", for: .normal)
            rv.addTarget(self, action: #selector(onBecomeDriver), for: .touchUpInside)
            rv.isHidden = leg.isClaimed
            return rv
        }()

        view.addSubviews([labels, becomeDriverButton])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        labels.frame = CGRect(x: margin, y: margin, width: width - margin * 2, height: 200)
        becomeDriverButton.frame = CGRect(x: margin, y: height - 44 - margin, width: width - margin * 2, height: 44)
    }

    @objc func onBecomeDriver() {
        let alert = UIAlertController(title: "Claim this leg?", message: "Confirm that you would like to be the driver for this leg.", preferredStyle: .alert)
        alert.addAction(.init(title: "I'm the driver", style: .default, handler: { _ in self.becomeDriverButton.isHidden = true })) //TODO: Update the leg
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
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
