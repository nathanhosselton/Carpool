import UIKit
import MapKit
import CarpoolKit

private let margin = 8.f

private enum CreateTripError: UserError {
    case invalidTrip

    var description: String {
        switch self {
        case .invalidTrip:
            return "All fields must be filled in before you can create the trip."
        }
    }
}

final class CreateTripViewController: UIViewController {
    private let name: UITextField
    private let destination: UITextField
    private let map: MKMapView
    private let byWhen: UILabel
    private let datePicker: UIDatePicker
    private let confirm: UIButton
    private let stack: UIStackView

    private var scroll: UIScrollView {
        return view as! UIScrollView
    }

    required init(coder: NSCoder = .null) {
        name = UITextField(.byhand, placeholder: "Who needs to get somewhere?")
        destination = UITextField(.byhand, placeholder: "Where are they going?")
        map = MKMapView()
        byWhen = UILabel("By when?")
        datePicker = UIDatePicker()
        confirm = UIButton(.byhand, title: "Create Trip", font: UIFont.systemFont(ofSize: UIFont.buttonFontSize))
        stack = UIStackView(arrangedSubviews: [name, destination, map, byWhen, datePicker, confirm])

        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        self.view = UIScrollView()
        super.viewDidLoad()

        self.title = "Create a Trip"
        view.backgroundColor = .white
        edgesForExtendedLayout = []

        map.isHidden = true
        map.addConstraint(NSLayoutConstraint(item: map, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 150))

        datePicker.minimumDate = Date()

        confirm.addTarget(self, action: #selector(onConfirm), for: .touchUpInside)

        stack.axis = .vertical
        stack.distribution = .fillProportionally
        stack.spacing = margin * 2

        view.addSubview(stack)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        stack.size = stack.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        stack.width = width
        stack.origin = .zero
        scroll.contentSize = stack.size
    }

    var eventDescription: String? {
        guard let name = name.realText, let dest = destination.realText else { return nil }
        return "Get \(name) to \(dest) by \(DateFormatter.forEvents.string(from: datePicker.date))"
    }

    @objc func onConfirm() {
        guard let desc = eventDescription else { return show(CreateTripError.invalidTrip) }

        API.createTrip(eventDescription: desc, eventTime: datePicker.date, eventLocation: CLLocation()) { (newTrip) in
            print(newTrip)
        }
    }

}
