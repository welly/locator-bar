import AppKit
import CoreLocation
import SwiftUI

@main
struct LocatorBarApp: App {
    @StateObject private var location = LocationModel()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(location: location)
        } label: {
            Text(location.locator ?? "––––––")
                .monospacedDigit()
        }
    }
}

struct MenuContent: View {
    @ObservedObject var location: LocationModel

    var body: some View {
        if let loc = location.current {
            let lat = loc.coordinate.latitude, lon = loc.coordinate.longitude
            Text(Maidenhead.locator(latitude: lat, longitude: lon, pairs: 4))
            Text(String(format: "%.5f, %.5f", lat, lon))
            Text("±\(Int(loc.horizontalAccuracy)) m")
            Divider()
            Text("CQ Zone: \(location.cqZone.map(String.init) ?? "–")")
            Text("ITU Zone: \(location.ituZone.map(String.init) ?? "–")")
            if let wab = location.wab {
                Text("WAB Square: \(wab)")
            }
            Divider()
            Button("Copy Locator") { copy(location.locator ?? "") }
                .keyboardShortcut("c")
            Button("Copy Coordinates") { copy(String(format: "%.5f, %.5f", lat, lon)) }
        } else {
            Text(location.status)
        }
        Divider()
        Button("Refresh") { location.refresh() }
            .keyboardShortcut("r")
        if location.denied {
            Button("Open Location Settings…") {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices")!)
            }
        }
        Button("Quit") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }

    private func copy(_ s: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(s, forType: .string)
    }
}

final class LocationModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var current: CLLocation? {
        didSet {
            guard let c = current?.coordinate else { return }
            cqZone = Zones.cqZone(latitude: c.latitude, longitude: c.longitude)
            ituZone = Zones.ituZone(latitude: c.latitude, longitude: c.longitude)
            wab = WAB.square(latitude: c.latitude, longitude: c.longitude)
        }
    }
    @Published var cqZone: Int?
    @Published var ituZone: Int?
    @Published var wab: String?
    @Published var status = "Locating…"
    @Published var denied = false

    var locator: String? {
        current.map { Maidenhead.locator(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude) }
    }

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 200   // a 6-char square is roughly 5 × 2.5 km
    }

    func refresh() {
        manager.requestLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            status = "Waiting for permission…"
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            denied = true
            status = "Location access denied"
        default:
            denied = false
            status = "Locating…"
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let last = locations.last { current = last }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if current == nil { status = "Location unavailable" }
    }
}
