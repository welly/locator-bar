import Foundation

/// Worked All Britain square: the 10 km National Grid square, e.g. "TQ38" (OS grid, Great Britain
/// and Isle of Man), "J37" (Irish Grid) or "WV64" (Channel Islands, from UTM zone 30).
/// Returns nil outside those areas. The area tests are rough outlines; offshore results may be off.
enum WAB {
    static func square(latitude lat: Double, longitude lon: Double) -> String? {
        if (49.1...49.8).contains(lat) && (-2.8 ... -1.9).contains(lon) { return channelIslands(lat, lon) }
        if inside(ireland, lon, lat) { return irish(lat, lon) }
        if inside(britain, lon, lat) { return british(lat, lon) }
        return nil
    }

    // MARK: Areas (lon, lat)

    /// Island of Ireland, separated from Scotland, the Isle of Man and Wales.
    private static let ireland: [(Double, Double)] = [
        (-11, 51.3), (-5.8, 51.3), (-5.8, 54.0), (-5.3, 54.0), (-5.3, 55.0),
        (-6.0, 55.3), (-7.0, 55.45), (-7.5, 55.5), (-11, 55.5),
    ]
    /// Great Britain and nearby islands, cut off from France and the Low Countries.
    private static let britain: [(Double, Double)] = [
        (-9, 49.8), (0.5, 49.8), (1.4, 50.85), (2.0, 51.25), (2.5, 51.6), (2.5, 61.5), (-9, 61.5),
    ]

    private static func inside(_ poly: [(Double, Double)], _ x: Double, _ y: Double) -> Bool {
        var result = false
        var j = poly.count - 1
        for i in poly.indices {
            let (xi, yi) = poly[i], (xj, yj) = poly[j]
            if (yi > y) != (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi { result.toggle() }
            j = i
        }
        return result
    }

    // MARK: Grids

    private static func british(_ lat: Double, _ lon: Double) -> String? {
        let (la, lo) = helmert(lat, lon, to: airy, tx: -446.448, ty: 125.157, tz: -542.060,
                               s: 20.4894, rx: -0.1502, ry: -0.2470, rz: -0.8421)
        let (e, n) = transverseMercator(la, lo, airy, f0: 0.9996012717, lat0: 49, lon0: -2, e0: 400_000, n0: -100_000)
        guard e >= 0, e < 700_000, n >= 0, n < 1_300_000 else { return nil }
        let e100 = Int(e / 100_000), n100 = Int(n / 100_000)
        var l1 = (19 - n100) - (19 - n100) % 5 + (e100 + 10) / 5
        var l2 = (19 - n100) * 5 % 25 + e100 % 5
        if l1 > 7 { l1 += 1 }   // the grid alphabet skips I
        if l2 > 7 { l2 += 1 }
        return letter(l1) + letter(l2) + digits(e, n)
    }

    private static func irish(_ lat: Double, _ lon: Double) -> String? {
        let (la, lo) = helmert(lat, lon, to: airyModified, tx: -482.53, ty: 130.596, tz: -564.557,
                               s: -8.15, rx: 1.042, ry: 0.214, rz: 0.631)
        let (e, n) = transverseMercator(la, lo, airyModified, f0: 1.000035, lat0: 53.5, lon0: -8, e0: 200_000, n0: 250_000)
        guard e >= 0, e < 500_000, n >= 0, n < 500_000 else { return nil }
        let letters = Array("ABCDEFGHJKLMNOPQRSTUVWXYZ")
        return String(letters[(4 - Int(n / 100_000)) * 5 + Int(e / 100_000)]) + digits(e, n)
    }

    /// MGRS 100 km square letters in UTM zone 30 (WGS84), as used by WAB for the Channel Islands.
    private static func channelIslands(_ lat: Double, _ lon: Double) -> String {
        let (e, n) = transverseMercator(lat, lon, wgs84, f0: 0.9996, lat0: 0, lon0: -3, e0: 500_000, n0: 0)
        let columns = Array("STUVWXYZ"), rows = Array("FGHJKLMNPQRSTUVABCDE")   // zone 30 letter sets
        return String(columns[Int(e / 100_000) - 1]) + String(rows[Int(n / 100_000) % 20]) + digits(e, n)
    }

    private static func letter(_ i: Int) -> String { String(UnicodeScalar(UInt8(65 + i))) }

    private static func digits(_ e: Double, _ n: Double) -> String {
        "\(Int(e.truncatingRemainder(dividingBy: 100_000) / 10_000))\(Int(n.truncatingRemainder(dividingBy: 100_000) / 10_000))"
    }

    // MARK: Geodesy

    private struct Ellipsoid { let a: Double, b: Double }
    private static let wgs84 = Ellipsoid(a: 6_378_137, b: 6_356_752.314245)
    private static let airy = Ellipsoid(a: 6_377_563.396, b: 6_356_256.909)
    private static let airyModified = Ellipsoid(a: 6_377_340.189, b: 6_356_034.447)

    /// WGS84 lat/lon (height 0) → lat/lon on another datum. Translations in metres, scale in ppm,
    /// rotations in arc seconds (position-vector convention, as published by Ordnance Survey).
    private static func helmert(_ lat: Double, _ lon: Double, to target: Ellipsoid,
                                tx: Double, ty: Double, tz: Double,
                                s: Double, rx: Double, ry: Double, rz: Double) -> (Double, Double) {
        let φ = lat * .pi / 180, λ = lon * .pi / 180
        let e2 = 1 - pow(wgs84.b / wgs84.a, 2)
        let ν = wgs84.a / sqrt(1 - e2 * sin(φ) * sin(φ))
        let x = ν * cos(φ) * cos(λ), y = ν * cos(φ) * sin(λ), z = ν * (1 - e2) * sin(φ)

        let sec = Double.pi / 180 / 3600
        let k = 1 + s / 1e6, ax = rx * sec, ay = ry * sec, az = rz * sec
        let x2 = tx + k * (x - az * y + ay * z)
        let y2 = ty + k * (az * x + y - ax * z)
        let z2 = tz + k * (-ay * x + ax * y + z)

        let te2 = 1 - pow(target.b / target.a, 2)
        let p = sqrt(x2 * x2 + y2 * y2)
        var φ2 = atan2(z2, p * (1 - te2))
        for _ in 0..<6 {
            let ν2 = target.a / sqrt(1 - te2 * sin(φ2) * sin(φ2))
            φ2 = atan2(z2 + te2 * ν2 * sin(φ2), p)
        }
        return (φ2 * 180 / .pi, atan2(y2, x2) * 180 / .pi)
    }

    /// Transverse Mercator projection (Ordnance Survey series formulae).
    private static func transverseMercator(_ lat: Double, _ lon: Double, _ el: Ellipsoid,
                                           f0: Double, lat0: Double, lon0: Double,
                                           e0: Double, n0: Double) -> (Double, Double) {
        let a = el.a, b = el.b
        let φ = lat * .pi / 180, λ = lon * .pi / 180, φ0 = lat0 * .pi / 180, λ0 = lon0 * .pi / 180
        let e2 = 1 - (b * b) / (a * a), n = (a - b) / (a + b)
        let sinφ = sin(φ), cosφ = cos(φ), tanφ = tan(φ)
        let ν = a * f0 / sqrt(1 - e2 * sinφ * sinφ)
        let ρ = a * f0 * (1 - e2) / pow(1 - e2 * sinφ * sinφ, 1.5)
        let η2 = ν / ρ - 1
        let dφ = φ - φ0, sφ = φ + φ0
        let m = b * f0 * ((1 + n + 1.25 * n * n + 1.25 * n * n * n) * dφ
            - (3 * n + 3 * n * n + 21.0 / 8 * n * n * n) * sin(dφ) * cos(sφ)
            + (15.0 / 8 * n * n + 15.0 / 8 * n * n * n) * sin(2 * dφ) * cos(2 * sφ)
            - 35.0 / 24 * n * n * n * sin(3 * dφ) * cos(3 * sφ))
        let i = m + n0
        let ii = ν / 2 * sinφ * cosφ
        let iii = ν / 24 * sinφ * pow(cosφ, 3) * (5 - tanφ * tanφ + 9 * η2)
        let iiia = ν / 720 * sinφ * pow(cosφ, 5) * (61 - 58 * tanφ * tanφ + pow(tanφ, 4))
        let iv = ν * cosφ
        let v = ν / 6 * pow(cosφ, 3) * (ν / ρ - tanφ * tanφ)
        let vi = ν / 120 * pow(cosφ, 5) * (5 - 18 * tanφ * tanφ + pow(tanφ, 4) + 14 * η2 - 58 * tanφ * tanφ * η2)
        let dλ = λ - λ0
        let north = i + ii * dλ * dλ + iii * pow(dλ, 4) + iiia * pow(dλ, 6)
        let east = e0 + iv * dλ + v * pow(dλ, 3) + vi * pow(dλ, 5)
        return (east, north)
    }
}
