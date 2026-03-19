import Foundation
import Network
import AppKit
import Combine
import CoreWLAN

@MainActor
final class ConnectivityModel: ObservableObject {

    enum State {
        case online
        case limited
        case offline
    }

    @Published private(set) var state: State = .offline
    @Published private(set) var detail: String = "Starting…"

    var iconName: String {
        switch state {
        case .online:  return "checkmark.circle"
        case .limited: return "exclamationmark.triangle"
        case .offline: return "xmark.circle"
        }
    }

    var stateTitle: String {
        switch state {
        case .online:  return "ONLINE"
        case .limited: return "LOGIN REQUIRED?"
        case .offline: return "OFFLINE"
        }
    }

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "net.monitor.queue")

    private var periodicTask: Task<Void, Never>?
    private var debounceTask: Task<Void, Never>?

    // Captive portal trigger/probe URL
    private let probeURL = URL(string: "http://captive.apple.com/hotspot-detect.html")!

    init() {
        startPathMonitor()
        startPeriodicChecks()
        checkNow()
    }

    deinit {
        monitor.cancel()
        periodicTask?.cancel()
        debounceTask?.cancel()
    }

    func openLoginPage() {
        NSWorkspace.shared.open(probeURL)
    }

    func openWiFiSettings() {
        // macOS 13+ Wi-Fi settings deep link
        if let url = URL(string: "x-apple.systempreferences:com.apple.wifi-settings-extension") {
            NSWorkspace.shared.open(url)
        }
    }

    func reconnectWiFi() {
        // Best-effort: disassociate and let macOS auto-join again
        guard let iface = CWWiFiClient.shared().interface() else {
            setState(.limited, "No Wi-Fi interface found")
            return
        }

        do {
            try iface.disassociate()
            setState(.limited, "Disconnected. Waiting for auto-join…")
            // Optional: check again shortly
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2s
                await self.performCheck()
            }
        } catch {
            setState(.limited, "Reconnect failed: \(error.localizedDescription)")
        }
    }
    
    func checkNow() {
        Task { await performCheck() }
    }

    private func startPathMonitor() {
        monitor.pathUpdateHandler = { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                // Debounce to avoid rapid flapping
                self.debounceTask?.cancel()
                self.debounceTask = Task {
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s
                    await self.performCheck()
                }
            }
        }
        monitor.start(queue: monitorQueue)
    }

    private func startPeriodicChecks() {
        periodicTask = Task {
            while !Task.isCancelled {
                await performCheck()
                try? await Task.sleep(nanoseconds: 60_000_000_000) // 60s
            }
        }
    }

    private func setState(_ newState: State, _ newDetail: String) {
        state = newState
        detail = newDetail
    }

    private func performCheck() async {
        // 1) Check network path first
        let path = monitor.currentPath

        switch path.status {
        case .satisfied:
            break // 続けてHTTPプローブへ

        case .requiresConnection:
            setState(.limited, "Network requires connection (possible captive portal)")
            return

        case .unsatisfied:
            setState(.offline, "No network route")
            return

        @unknown default:
            setState(.limited, "Unknown network status")
            return
        }
        
        // 2) HTTP probe to detect captive / reachability
        var request = URLRequest(url: probeURL)
        request.timeoutInterval = 4.0
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                setState(.limited, "Unexpected response (not HTTP)")
                return
            }

            // Redirect often indicates captive interception
            if (300...399).contains(http.statusCode) {
                setState(.limited, "Redirected (possible captive portal)")
                return
            }

            let body = String(data: data, encoding: .utf8) ?? ""
            if http.statusCode == 200, body.contains("Success") {
                setState(.online, "Internet reachable")
            } else {
                setState(.limited, "Blocked or captive (code \(http.statusCode))")
            }
        } catch {
            setState(.limited, "Probe failed: \(error.localizedDescription)")
        }
    }
}
