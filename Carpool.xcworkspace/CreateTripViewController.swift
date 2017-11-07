import UIKit

private let margin = 8.f

final class CreateTripViewController: UIViewController {
    let eventDescription = UITextField(.byhand, placeholder: "Enter a description for this trip")
    let eventDatePicker = UIDatePicker()
    let confirm = UIButton(.byhand, title: "Create Trip", font: UIFont.systemFont(ofSize: UIFont.buttonFontSize))

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Create a Trip"
        view.backgroundColor = .white
        edgesForExtendedLayout = []

        eventDatePicker.minimumDate = Date()
        confirm.addTarget(self, action: #selector(onConfirm), for: .touchUpInside)

        view.addSubviews([eventDescription, eventDatePicker, confirm])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        eventDescription.origin = CGPoint(x: margin, y: margin)
        eventDescription.width = width - margin * 2

        eventDatePicker.center.x = view.center.x
        eventDatePicker.width = width
        eventDatePicker.minY = eventDescription.maxY + margin * 2
        
        confirm.center.x = view.center.x
        confirm.maxY = view.maxY - margin
    }

    @objc func onConfirm() {
        //TODO:
    }

}
