import AppKit
import CoreLocation
import ServiceManagement
import SwiftUI

@main
struct LocatorBarApp: App {
    @StateObject private var location = LocationModel()
    @StateObject private var loginItem = LaunchAtLogin()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(location: location, loginItem: loginItem)
        } label: {
            Text(location.locator ?? "––––––")
                .monospacedDigit()
        }
    }
}

struct MenuContent: View {
    @ObservedObject var location: LocationModel
    @ObservedObject var loginItem: LaunchAtLogin

    var body: some View {
        if let loc = location.current {
            let lat = loc.coordinate.latitude, lon = loc.coordinate.longitude
            Text(Maidenhead.locator(latitude: lat, longitude: lon, pairs: 4))
            Text(String(format: "%.5f, %.5f", lat, lon))
            Text("±\(Int(loc.horizontalAccuracy)) m")
            Text("Fix: \(Self.utc.string(from: loc.timestamp))")
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
        Toggle("Launch at Login", isOn: Binding(
            get: { loginItem.isEnabled },
            set: { loginItem.setEnabled($0) }
        ))
        .onAppear { loginItem.reload() }
        if loginItem.needsApproval {
            Button("Allow in Login Items Settings…") { SMAppService.openSystemSettingsLoginItems() }
        }
        if location.denied {
            Button("Open Location Settings…") {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices")!)
            }
        }
        Button("About Locator") {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.orderFrontStandardAboutPanel(options: [
                .credits: NSAttributedString(
                    string: "CQ and ITU zone boundaries from HB9HIL/hamradio-zones-geojson (MIT licence).\nYour position never leaves this Mac.",
                    attributes: [.font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)]
                )
            ])
        }
        Button("Quit") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }

    /// Operator-facing UTC time, e.g. `2026-11-10 2003Z`.
    private static let utc: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd HHmm'Z'"
        return f
    }()

    private func copy(_ s: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(s, forType: .string)
    }
}

/// Registers the app as a login item via ServiceManagement. Only works from a built `.app` bundle.
final class LaunchAtLogin: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var needsApproval = false

    init() { reload() }

    func reload() {
        let status = SMAppService.mainApp.status
        isEnabled = status == .enabled
        needsApproval = status == .requiresApproval
    }

    func setEnabled(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            NSLog("Launch at login: \(error.localizedDescription)")
        }
        reload()
        if on && needsApproval { SMAppService.openSystemSettingsLoginItems() }
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
