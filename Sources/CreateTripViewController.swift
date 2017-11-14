import UIKit
import MapKit
import CarpoolKit

private let margin = 8.f

private enum CreateTripError: UserError {
    case invalidTrip
    case userDeniedLocation
    case needsLogin

    var description: String {
        switch self {
        case .invalidTrip:
            return "All fields must be filled in before you can create the trip."
        case .userDeniedLocation:
            return "We'll be unable to provide accurate destination lookups for you without your location. You can enable this later in the Privacy Settings of your device."
        case .needsLogin:
            return "You must login before creating a Trip."
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
    private let fields: UIStackView
    private let stack: UIStackView

    private let locationAdapter = LocationManagerAdapter()
    private var endPoint: CLLocation?

    private var scroll: UIScrollView {
        return view as! UIScrollView
    }

    required init(coder: NSCoder = .null) {
        name = UITextField(.byhand, placeholder: "Who needs to get somewhere?")
        destination = UITextField(.byhand, placeholder: "Where are they going?")
        map = MKMapView()
        byWhen = UILabel(.byhand, "  By when?")
        datePicker = UIDatePicker()
        confirm = UIButton(.byhand, title: "Create Trip", font: UIFont.systemFont(ofSize: UIFont.buttonFontSize))
        fields = UIStackView(arrangedSubviews: [name, destination])
        stack = UIStackView(arrangedSubviews: [fields, map, byWhen, datePicker, confirm])

        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        self.view = UIScrollView()
        super.viewDidLoad()

        self.title = "Create a Trip"
        view.backgroundColor = .white
        edgesForExtendedLayout = []

        //View config

        map.delegate = self
        map.isHidden = true
        map.addConstraint(NSLayoutConstraint(item: map, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 150))

        byWhen.font = .systemFont(ofSize: 18)
        byWhen.textColor = name.attributedPlaceholder?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as! UIColor
        byWhen.sizeToFit()

        destination.enablesReturnKeyAutomatically = true
        destination.addTarget(self, action: #selector(onDestinationReturn), for: .editingDidEndOnExit)

        datePicker.minimumDate = Date()

        confirm.addTarget(self, action: #selector(onConfirm), for: .touchUpInside)

        fields.axis = .vertical
        fields.distribution = .fillProportionally
        fields.spacing = margin * 2
        fields.directionalLayoutMargins = .init(top: 0, leading: margin, bottom: 0, trailing: margin)
        fields.isLayoutMarginsRelativeArrangement = true

        stack.axis = .vertical
        stack.distribution = .fillProportionally
        stack.spacing = margin * 2

        view.addSubview(stack)

        //Etc

        locationAdapter.confirmAccess { (result) in
            switch result {
            case .granted: self.map.showsUserLocation = true
            case .denied: self.show(CreateTripError.userDeniedLocation)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        stack.size = stack.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        stack.width = width
        stack.origin = CGPoint(x: 0, y: margin)
        scroll.contentSize = stack.size
    }

    private func revealMap() {
        guard map.isHidden else { return }
        map.isHidden = false
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    @objc func onDestinationReturn() {
        guard let query = destination.text?.chuzzled else { return }

        MKLocalSearch(request: .init(query)).start { (resp, error) in
            guard let resp = resp else { return print(error!) }

            let resultsVC = SearchResultsTableViewController(results: resp.mapItems, onSelection: { (mapItem) in
                self.revealMap()
                self.map.addAnnotation(mapItem.placemark)

                self.destination.text = mapItem.name
                self.endPoint = mapItem.placemark.location

                self.dismiss(animated: true, completion: nil)
            }).inNav(rightBarButton: UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.onResultsDismiss)))

            self.present(resultsVC, animated: true)
        }
    }

    private var eventDescription: String? {
        guard let name = name.text?.chuzzled, let dest = destination.text?.chuzzled else { return nil }
        return "Get \(name) to \(dest)"
    }

    @objc func onConfirm() {
        guard let desc = eventDescription else { return show(CreateTripError.invalidTrip) }

        API.createTrip(eventDescription: desc, eventTime: datePicker.date, eventLocation: endPoint ?? CLLocation()) { (result) in
            switch result {
            case .success(_):
                self.navigationController?.popToRootViewController(animated: true)
            case .failure(API.Error.anonymousUsersCannotCreateTrips):
                self.showLoginPrompt()
            case .failure(let error):
                self.show(error)
            }
        }
    }

    @objc func onResultsDismiss() {
        dismiss(animated: true)
    }

    @objc func onLoginDismiss() {
        dismiss(animated: true)
    }

    private func showLoginPrompt() {
        let alert = UIAlertController(title: "Hold up", message: CreateTripError.needsLogin.localizedDescription, preferredStyle: .alert)
        alert.addAction(.init(title: "Let's go", style: .default) { _ in
            let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.onLoginDismiss))
            self.present(LoginViewController().inNav(rightBarButton: cancel), animated: true)
        })
        alert.addAction(.init(title: "Never mind", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }

}

extension CreateTripViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        map.showAnnotations(views.flatMap{ $0.annotation }, animated: true)
    }
}



private final class SearchResultsTableViewController: UITableViewController {
    let results: [MKMapItem]
    let completion: (MKMapItem) -> Void

    init(results: [MKMapItem], onSelection: @escaping (MKMapItem) -> Void) {
        self.results = results
        self.completion = onSelection
        super.init(style: .plain)
        self.title = "Confirm Destination"
    }

    required init?(coder: NSCoder) {
        fatalError("SearchResultsTableViewController.init(coder:) has not been implemented")
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = results[indexPath.row].name
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        completion(results[indexPath.row])
    }
}



private final class LocationManagerAdapter: NSObject, CLLocationManagerDelegate {
    enum AccessResult {
        case granted
        case denied
    }

    enum LocationResult {
        case success(CLLocation)
        case failure(Error)

        enum Error {
            case userDenied, requestFailed(Swift.Error)
        }
    }

    private let locationManager = CLLocationManager()
    private var userLocation: CLLocation?
    private var accessRequestCompletion: ((AccessResult) -> Void)?
    private var userLocationCompletion: ((LocationResult) -> Void)?

    func confirmAccess(_ completion: @escaping (AccessResult) -> Void) {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            DispatchQueue.main.async { completion(.granted) }
        case .notDetermined:
            accessRequestCompletion = completion
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            DispatchQueue.main.async { completion(.denied) }
        }
    }

    func requestUserLocation(_ completion: @escaping (LocationResult) -> Void) {
        if let loc = userLocation {
            DispatchQueue.main.async { completion(.success(loc)) }
        }

        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            userLocationCompletion = completion
            locationManager.requestLocation()
        case .notDetermined:
            userLocationCompletion = completion
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            DispatchQueue.main.async { completion(.failure(.userDenied)) }
        }
    }

    func locationManager(_ _: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            accessRequestCompletion?(.granted)
            accessRequestCompletion = nil
            locationManager.requestLocation()
        case .notDetermined, .restricted, .denied:
            userLocationCompletion?(.failure(.userDenied))
            accessRequestCompletion?(.denied)
            accessRequestCompletion = nil
            userLocationCompletion = nil
        }
    }

    func locationManager(_ _: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.first!
        userLocationCompletion?(.success(userLocation!))
        userLocationCompletion = nil
    }

    func locationManager(_ _: CLLocationManager, didFailWithError error: Error) {
        userLocationCompletion?(.failure(.requestFailed(error)))
        userLocationCompletion = nil
    }

}



private extension MKLocalSearchRequest {
    convenience init(_ query: String) {
        self.init()
        naturalLanguageQuery = query
    }
}
