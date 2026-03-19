import AppKit
import Combine
import os

private let logger = Logger(subsystem: "com.totsuji.CaptiveWifiHelper", category: "lifecycle")

class AppDelegate: NSObject, NSApplicationDelegate {
    private var activity: NSObjectProtocol?
    private var statusItem: NSStatusItem!
    private let model = ConnectivityModel()
    private var cancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 自動終了を無効化
        ProcessInfo.processInfo.automaticTerminationSupportEnabled = false
        ProcessInfo.processInfo.disableAutomaticTermination("CaptiveWifiHelper must run continuously")
        ProcessInfo.processInfo.disableSuddenTermination()
        activity = ProcessInfo.processInfo.beginActivity(
            options: .userInitiated,
            reason: "Background network monitoring"
        )

        // メニューバーアイテムを作成
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: model.iconName, accessibilityDescription: nil)

        // model の状態変化でアイコンとメニューを更新
        cancellable = model.objectWillChange.sink { [weak self] _ in
            Task { @MainActor in
                self?.updateStatusItem()
            }
        }

        updateStatusItem()
    }

    func applicationWillTerminate(_ notification: Notification) {
        logger.error("applicationWillTerminate called — app is being terminated")
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        logger.error("applicationShouldTerminate called")
        return .terminateNow
    }

    func applicationShouldTerminateAfterLastWindowIsClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    @MainActor
    private func updateStatusItem() {
        statusItem.button?.image = NSImage(systemSymbolName: model.iconName, accessibilityDescription: nil)
        statusItem.menu = buildMenu()
    }

    @MainActor
    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let titleItem = NSMenuItem(title: model.stateTitle, action: nil, keyEquivalent: "")
        titleItem.attributedTitle = NSAttributedString(
            string: model.stateTitle,
            attributes: [.font: NSFont.boldSystemFont(ofSize: 13)]
        )
        menu.addItem(titleItem)

        let detailItem = NSMenuItem(title: model.detail, action: nil, keyEquivalent: "")
        detailItem.attributedTitle = NSAttributedString(
            string: model.detail,
            attributes: [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.secondaryLabelColor]
        )
        menu.addItem(detailItem)

        menu.addItem(.separator())

        let checkItem = NSMenuItem(title: "Check Now", action: #selector(checkNow), keyEquivalent: "")
        checkItem.target = self
        menu.addItem(checkItem)

        let openItem = NSMenuItem(title: "Open Login Page", action: #selector(openLoginPage), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)

        if model.state == .limited {
            menu.addItem(.separator())

            let reconnectItem = NSMenuItem(title: "Reconnect Wi-Fi (disconnect / auto-join)", action: #selector(reconnectWiFi), keyEquivalent: "")
            reconnectItem.target = self
            menu.addItem(reconnectItem)

            let settingsItem = NSMenuItem(title: "Open Wi-Fi Settings…", action: #selector(openWiFiSettings), keyEquivalent: "")
            settingsItem.target = self
            menu.addItem(settingsItem)

            let hintItem = NSMenuItem(title: "If login page doesn't appear, try reconnecting Wi-Fi.", action: nil, keyEquivalent: "")
            hintItem.attributedTitle = NSAttributedString(
                string: "If login page doesn't appear, try reconnecting Wi-Fi.",
                attributes: [.font: NSFont.systemFont(ofSize: 10), .foregroundColor: NSColor.secondaryLabelColor]
            )
            menu.addItem(hintItem)
        }

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    @objc private func checkNow() {
        model.checkNow()
    }

    @objc private func openLoginPage() {
        model.openLoginPage()
    }

    @objc private func reconnectWiFi() {
        model.reconnectWiFi()
    }

    @objc private func openWiFiSettings() {
        model.openWiFiSettings()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
