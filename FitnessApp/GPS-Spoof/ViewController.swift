import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {

    private let locationManager = CLLocationManager()
    private var fakeLocationManager: FakeLocationManager?
    private var timer: Timer?

    private let fakeLabel = UILabel()
    private let realLabel = UILabel()

    private var realCoordinate: CLLocationCoordinate2D?
    private var fakeCoordinate: CLLocationCoordinate2D?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        startLocationUpdates()
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

    func startLocationUpdates() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func loadFakeLocationData() {
        guard let path = Bundle.main.url(forResource: "TrackLocation", withExtension: "gpx"),
              let gpxData = try? Data(contentsOf: path) else {
            print("❌ Missing GPX")
            return
        }

        fakeLocationManager = FakeLocationManager(gpxData: gpxData)

        // Simulate updates every 5 seconds
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

        let real = realCoordinate ?? fake // If real is missing, use fake to avoid crash

        let fakeText = String(format: "Fake: %.8f, %.8f", fake.latitude, fake.longitude)
        let realText = String(format: "Real: %.8f, %.8f", real.latitude, real.longitude)

        fakeLabel.text = fakeText
        realLabel.text = realText

        if abs(fake.latitude - real.latitude) < 0.00001 &&
           abs(fake.longitude - real.longitude) < 0.00001 {
            // 🔴 Match = problem
            fakeLabel.textColor = .red
        } else {
            // ✅ Fake differs = working
            fakeLabel.textColor = .green
        }
    }
}
