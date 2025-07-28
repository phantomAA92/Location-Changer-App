import UIKit
import MapKit
import CoreLocation
import Network

class ViewController: UIViewController, CLLocationManagerDelegate {

    private let locationManager = CLLocationManager()
    private var fakeLocationManager: FakeLocationManager?
    private var timer: Timer?

    private let fakeLabel = UILabel()
    private let realLabel = UILabel()

    private var realCoordinate: CLLocationCoordinate2D?
    private var fakeCoordinate: CLLocationCoordinate2D?

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")

    private var noInternetAlert: UIAlertController?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startNetworkMonitor()
        loadFakeLocationData()
    }

    func setupUI() {
        view.backgroundColor = .black

        fakeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .bold)
        fakeLabel.textAlignment = .center
        fakeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fakeLabel)

        realLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .bold)
        realLabel.textAlignment = .center
        realLabel.textColor = .white
        realLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(realLabel)

        NSLayoutConstraint.activate([
            fakeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            fakeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            realLabel.topAnchor.constraint(equalTo: fakeLabel.bottomAnchor, constant: 12),
            realLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    func startNetworkMonitor() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    self.dismissNoInternetAlertIfNeeded()
                    self.startLocationUpdates()
                } else {
                    self.stopLocationUpdates()
                    self.showNoInternetAlert()
                }
            }
        }
        monitor.start(queue: monitorQueue)
    }

    func showNoInternetAlert() {
        guard noInternetAlert == nil else { return }

        let alert = UIAlertController(
            title: "No Internet Connection",
            message: "Internet is required to track your location. GPS tracking has been disabled.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default))
        noInternetAlert = alert

        if self.presentedViewController == nil {
            self.present(alert, animated: true)
        }
    }

    func dismissNoInternetAlertIfNeeded() {
        if let alert = noInternetAlert {
            alert.dismiss(animated: true) {
                self.noInternetAlert = nil
            }
        }
    }

    func startLocationUpdates() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.delegate = nil
        self.realCoordinate = nil
        updateLabels()
    }

    func loadFakeLocationData() {
        guard let path = Bundle.main.url(forResource: "TrackLocation", withExtension: "gpx"),
              let gpxData = try? Data(contentsOf: path) else {
            print("❌ Missing GPX")
            return
        }

        fakeLocationManager = FakeLocationManager(gpxData: gpxData)

        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.updateFakeLocation()
        }
    }

    func updateFakeLocation() {
        guard let fakeLoc = fakeLocationManager?.getNextFakeLocation() else { return }
        self.fakeCoordinate = fakeLoc
        updateLabels()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = locations.last {
            self.realCoordinate = loc.coordinate
            updateLabels()
        }
    }

    func updateLabels() {
        guard let fake = fakeCoordinate else { return }

        let real = realCoordinate ?? fake

        let fakeText = String(format: "Fake: %.8f, %.8f", fake.latitude, fake.longitude)
        let realText = String(format: "Real: %.8f, %.8f", real.latitude, real.longitude)

        fakeLabel.text = fakeText
        realLabel.text = realText

        if abs(fake.latitude - real.latitude) < 0.00001 &&
            abs(fake.longitude - real.longitude) < 0.00001 {
            fakeLabel.textColor = .red
        } else {
            fakeLabel.textColor = .green
        }
    }

    deinit {
        monitor.cancel()
        timer?.invalidate()
    }
}
