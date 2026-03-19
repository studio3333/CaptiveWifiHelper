import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 自動終了を無効化
        ProcessInfo.processInfo.automaticTerminationSupportEnabled = false
        // 突然の終了を無効化
        ProcessInfo.processInfo.disableSuddenTermination()
        // App Nap を無効化（バックグラウンドネットワーク監視のため）
        ProcessInfo.processInfo.beginActivity(
            options: .userInitiated,
            reason: "Background network monitoring"
        )
    }
}

@main
struct CafeWifiHelperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var model = ConnectivityModel()

    var body: some Scene {
        MenuBarExtra {
            VStack(alignment: .leading, spacing: 8) {
                Text(model.stateTitle).font(.headline)
                Text(model.detail).font(.caption)

                Divider()

                Button("Check Now") {
                    model.checkNow()
                }

                Button("Open Login Page") {
                    model.openLoginPage()
                }

                if model.state == .limited {
                    Divider()

                    Button("Reconnect Wi-Fi (disconnect / auto-join)") {
                        model.reconnectWiFi()
                    }

                    Button("Open Wi-Fi Settings…") {
                        model.openWiFiSettings()
                    }

                    Text("If login page doesn’t appear, try reconnecting Wi-Fi.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Divider()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(8)
        } label: {
            Image(systemName: model.iconName)
        }
    }
}
