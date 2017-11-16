import UIKit
import MapKit
import CarpoolKit

private let margin = 8.f

final class TripDetailViewController: UIViewController {
    private let topLabels: StackView<UILabel>
    private let map: MKMapView?
    private let bottomLabels: StackView<UILabel>
    private let buttons: StackView<UIButton>
    private let stack: UIStackView

    private var trip: Trip {
        didSet {
            bottomLabels[0].text = "Dropoff driver: " + (trip.dropOff?.driver.name ?? "Not yet claimed")
            bottomLabels[2].text = "Pickup driver: " + (trip.pickUp?.driver.name ?? "Not yet claimed")

            buttons[0].setTitle(trip.titleForDropOffClaimButton, for: .normal)
            buttons[1].setTitle(trip.titleForPickUpClaimButton, for: .normal)

            buttons[0].isEnabled = trip.canModifyDropoff
            buttons[1].isEnabled = trip.canModifyPickup
        }
    }

    init(trip: Trip) {
        self.topLabels = StackView(arrangedSubviews: [
            UILabel(.byhand, trip.event.prettyDescription, .center),
            UILabel(.byhand, "Children: " + trip.prettyPrintedChildren, .center),
            UILabel(.byhand, "On: " + trip.event.prettyDate, .center),
            UILabel(.byhand, (trip.event.annotation != nil ? "Location:" : "")) //gross
        ])
        self.map = MKMapView(with: trip.event.annotation)
        self.bottomLabels = StackView(arrangedSubviews: [
            UILabel(.byhand, "Dropoff driver: " + (trip.dropOff?.driver.name ?? "Not yet claimed"), .center),
            UILabel(.byhand, "Pickup time: " + (trip.event.prettyEndDate ?? "Not set"), .center),
            UILabel(.byhand, "Pickup driver: " + (trip.pickUp?.driver.name ?? "Not yet claimed"), .center),
            UILabel(.byhand, "Parent: " + (trip.event.owner.name ?? "THIS SHOULDN'T HAPPEN"), .center)
        ])
        self.buttons = StackView(arrangedSubviews: [
            UIButton(.byhand),
            UIButton(.byhand)
        ])
        self.stack = UIStackView(arrangedSubviews: [
            self.topLabels,
            self.map ?? UIView(),
            self.bottomLabels,
            self.buttons
        ])

        self.trip = trip

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

        [topLabels, bottomLabels].forEach { (labels) in
            labels.spacing = margin * 2
            labels.axis = .vertical
            labels.directionalLayoutMargins = .init(top: 0, leading: margin, bottom: 0, trailing: margin)
            labels.isLayoutMarginsRelativeArrangement = true
            labels.views.forEach{ $0.numberOfLines = 0 }
        }

        map?.addConstraint(NSLayoutConstraint(item: map!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 150))

        buttons[0].addTarget(self, action: #selector(onClaimDropOff), for: .touchUpInside)
        buttons[1].addTarget(self, action: #selector(onClaimPickUp), for: .touchUpInside)
        buttons.spacing = margin * 2
        buttons.distribution = .fillProportionally
        buttons.directionalLayoutMargins = .init(top: 0, leading: margin, bottom: 0, trailing: margin)
        buttons.isLayoutMarginsRelativeArrangement = true

        stack.spacing = margin * 2
        stack.distribution = .fillProportionally
        stack.axis = .vertical

        view.addSubview(stack)

        API.observe(trip: trip, sender: self) { result in
            guard case .success(let trip) = result else { return }
            self.trip = trip
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        stack.size = stack.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        stack.width = width
        stack.origin = CGPoint(x: 0, y: margin)
    }

    @objc func onClaimDropOff(button: UIButton) {
        guard trip.canModifyDropoff else { return } //Shouldn't happen

        if trip.dropOffIsClaimed {
            API.unclaimDropOff(trip: trip).catch(execute: show)
        } else {
            API.claimDropOff(trip: trip).catch(execute: show)
        }
    }

    @objc func onClaimPickUp(button: UIButton) {
        guard trip.canModifyPickup else { return } //Shouldn't happen

        if trip.pickUpIsClaimed {
            API.unclaimPickUp(trip: trip).catch(execute: show)
        } else {
            API.claimPickUp(trip: trip).catch(execute: show)
        }
    }

}



private extension Trip {
    var titleForDropOffClaimButton: String {
        switch (dropOffIsClaimed, canModifyDropoff) {
        case (true, true): return (dropOff!.driver.isMe ? "Unclaim" : "Remove") + " Drop Off"
        case (true, false): return "Drop Off Claimed"
        case (false, _): return "Claim Drop Off"
        }
    }

    var titleForPickUpClaimButton: String {
        switch (pickUpIsClaimed, canModifyPickup) {
        case (true, true): return (pickUp!.driver.isMe ? "Unclaim" : "Remove") + " Pick Up"
        case (true, false): return "Pick Up Claimed"
        case (false, _): return "Claim Pick Up"
        }
    }
}



private extension MKMapView {
    convenience init?(with annotation: MKAnnotation?) {
        guard let annotation = annotation else { return nil }
        self.init()
        self.addAnnotation(annotation)
        self.showAnnotations([annotation], animated: false)
    }
}
