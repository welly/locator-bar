import Foundation

enum Maidenhead {
    /// Maidenhead locator for a position. `pairs` = 3 gives e.g. "IO91wm", 4 gives "IO91wm54".
    static func locator(latitude: Double, longitude: Double, pairs: Int = 3) -> String {
        var lon = min(max(longitude + 180, 0), 359.999999)
        var lat = min(max(latitude + 90, 0), 179.999999)
        // Size of one cell at each level, in degrees (lon, lat), and the alphabet for that level.
        let levels: [(Double, Double, String)] = [
            (20, 10, "ABCDEFGHIJKLMNOPQR"),
            (2, 1, "0123456789"),
            (2.0 / 24, 1.0 / 24, "abcdefghijklmnopqrstuvwx"),
            (2.0 / 240, 1.0 / 240, "0123456789"),
        ]
        var out = ""
        for (lonSize, latSize, chars) in levels.prefix(pairs) {
            let symbols = Array(chars)
            let x = Int(lon / lonSize), y = Int(lat / latSize)
            out.append(symbols[min(x, symbols.count - 1)])
            out.append(symbols[min(y, symbols.count - 1)])
            lon -= Double(x) * lonSize
            lat -= Double(y) * latSize
        }
        return out
    }
}
