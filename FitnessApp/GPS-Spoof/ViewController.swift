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
    private var isInternetAvailable = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startNetworkMonitor()
    }

    func setupUI() {
        view.backgroundColor = .black

        [fakeLabel, realLabel].forEach {
            $0.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .bold)
            $0.textAlignment = .center
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        realLabel.textColor = .white

        NSLayoutConstraint.activate([
            fakeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            fakeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            realLabel.topAnchor.constraint(equalTo: fakeLabel.bottomAnchor, constant: 12),
            realLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        clearLabels()
    }

    func startNetworkMonitor() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                let wasConnected = self.isInternetAvailable

                // ✅ Accept any satisfied path (including tethering under .other)
                self.isInternetAvailable = (path.status == .satisfied)

                if self.isInternetAvailable {
                    if !wasConnected {
                        self.dismissNoInternetAlertIfNeeded()
                        self.loadFakeLocationData()
                        self.startLocationUpdates()
                    }
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
            message: "Internet is required to track your location. Tracking has been disabled.",
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
        guard isInternetAvailable else { return }
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                self.updateFakeLocation()
            }
        }
    }

    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.delegate = nil
        realCoordinate = nil
        fakeCoordinate = nil

        timer?.invalidate()
        timer = nil
        clearLabels()
    }

    func clearLabels() {
        fakeLabel.text = ""
        realLabel.text = ""
    }

    func loadFakeLocationData() {
        guard fakeLocationManager == nil else { return }
        guard let path = Bundle.main.url(forResource: "TrackLocation", withExtension: "gpx"),
              let gpxData = try? Data(contentsOf: path) else {
            print("❌ Missing GPX file")
            return
        }
        fakeLocationManager = FakeLocationManager(gpxData: gpxData)
    }

    func updateFakeLocation() {
        guard isInternetAvailable,
              let fakeLoc = fakeLocationManager?.getNextFakeLocation() else { return }

        fakeCoordinate = fakeLoc
        updateLabels()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isInternetAvailable,
              let loc = locations.last else { return }

        realCoordinate = loc.coordinate
        updateLabels()
    }

    func updateLabels() {
        guard isInternetAvailable, let fake = fakeCoordinate else { return }

        let real = realCoordinate ?? fake
        fakeLabel.text = String(format: "Fake: %.8f, %.8f", fake.latitude, fake.longitude)
        realLabel.text = String(format: "Real: %.8f, %.8f", real.latitude, real.longitude)

        fakeLabel.textColor = (abs(fake.latitude - real.latitude) < 0.00001 &&
                               abs(fake.longitude - real.longitude) < 0.00001)
                                ? .red : .green
    }

    deinit {
        monitor.cancel()
        timer?.invalidate()
    }
}
