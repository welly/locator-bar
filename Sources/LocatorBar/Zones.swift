import Foundation

/// CQ and ITU zone lookup from bundled boundary polygons (HB9HIL/hamradio-zones-geojson, MIT).
enum Zones {
    static func cqZone(latitude: Double, longitude: Double) -> Int? {
        cq.first { $0.contains(lat: latitude, lon: longitude) }?.zone
    }

    static func ituZone(latitude: Double, longitude: Double) -> Int? {
        itu.first { $0.contains(lat: latitude, lon: longitude) }?.zone
    }

    // MARK: Polygon data

    private static let cq = load("cqzones")
    private static let itu = load("ituzones")

    private struct Zone: Decodable {
        let z: Int
        let r: [[Double]]   // rings as flat [lon, lat, lon, lat, ...]; longitudes may run past ±180

        var zone: Int { z }

        func contains(lat: Double, lon: Double) -> Bool {
            guard let ring = r.first else { return false }
            for l in [lon, lon + 360, lon - 360] where Self.inside(ring, x: l, y: lat) {
                return !r.dropFirst().contains { Self.inside($0, x: l, y: lat) }   // holes
            }
            return false
        }

        private static func inside(_ ring: [Double], x: Double, y: Double) -> Bool {
            var result = false
            let n = ring.count / 2
            var j = n - 1
            for i in 0..<n {
                let xi = ring[2 * i], yi = ring[2 * i + 1], xj = ring[2 * j], yj = ring[2 * j + 1]
                if (yi > y) != (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi { result.toggle() }
                j = i
            }
            return result
        }
    }

    private static func load(_ name: String) -> [Zone] {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let zones = try? JSONDecoder().decode([Zone].self, from: data) else { return [] }
        return zones
    }
}
