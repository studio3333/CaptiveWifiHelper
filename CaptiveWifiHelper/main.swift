import AppKit
import os

private let logger = Logger(subsystem: "com.totsuji.CaptiveWifiHelper", category: "lifecycle")

// AppDelegate を強参照で保持（NSApplication.delegate は weak のため）
private let appDelegate = AppDelegate()

let app = NSApplication.shared
app.delegate = appDelegate
logger.info("CaptiveWifiHelper started")
app.run()
logger.error("NSApplication.run() returned unexpectedly")
