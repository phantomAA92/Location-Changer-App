import Foundation
import CoreLocation

class GPXParser: NSObject, XMLParserDelegate {

    private(set) var coordinates: [CLLocationCoordinate2D] = []
    private var parser: XMLParser?

    func parse(data: Data) -> [CLLocationCoordinate2D] {
        coordinates = [] // Reset

        parser = XMLParser(data: data)
        parser?.delegate = self
        parser?.parse()

        print("✅ GPX Parsing Complete. Found \(coordinates.count) coordinates.")
        for (index, coord) in coordinates.enumerated() {
            print("🔹 Point \(index + 1): Lat: \(coord.latitude), Lon: \(coord.longitude)")
        }

        return coordinates
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {

        // ✅ Handle both wpt and trkpt
        if elementName == "wpt" || elementName == "trkpt" {
            if let latStr = attributeDict["lat"],
               let lonStr = attributeDict["lon"],
               let lat = Double(latStr),
               let lon = Double(lonStr) {

                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                coordinates.append(coordinate)
                print("📍 Parsed point - Lat: \(lat), Lon: \(lon)")
            }
        }
    }
}
