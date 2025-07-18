import Foundation
import CoreLocation

class FakeLocationManager {
    private var coordinates: [CLLocationCoordinate2D] = []
    private var index = 0

    init(gpxData: Data) {
        let parser = GPXParser()
        coordinates = parser.parse(data: gpxData)
    }

    func getNextFakeLocation() -> CLLocationCoordinate2D? {
        guard !coordinates.isEmpty else { return nil }
        let location = coordinates[index]
        index = (index + 1) % coordinates.count // loop
        return location
    }
}
