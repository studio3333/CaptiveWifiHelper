# CaptiveWifiHelper

A lightweight macOS menu bar app that detects captive portals (hotel, airport, café Wi-Fi login pages) and helps you get online quickly.

![macOS](https://img.shields.io/badge/macOS-15.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)

## What It Does

When you connect to a Wi-Fi network that requires a login page (captive portal), macOS doesn't always pop up the login window automatically. CaptiveWifiHelper sits in your menu bar and:

- **Monitors** your network connection in real time
- **Detects** captive portals by probing Apple's connectivity check endpoint
- **Shows** the current status with a clear icon:
  - `✓` — Online (full internet access)
  - `⚠` — Login required (captive portal detected)
  - `✗` — Offline (no network)
- **Opens** the captive portal login page with one click
- **Reconnects** Wi-Fi (disconnect + auto-join) to re-trigger the login prompt
- **Links** directly to macOS Wi-Fi Settings

## Installation

### Option A: Download the pre-built app

1. Go to the [Releases](https://github.com/studio3333/CaptiveWifiHelper/releases) page
2. Download `CaptiveWifiHelper.zip` from the latest release
3. Unzip and move `CaptiveWifiHelper.app` to your `/Applications` folder
4. Right-click the app → **Open** (required on first launch to bypass Gatekeeper for unsigned apps)

### Option B: Build from source

**Requirements:**
- macOS 15.0 or later
- Xcode 16 or later

```bash
git clone https://github.com/studio3333/CaptiveWifiHelper.git
cd CaptiveWifiHelper
open CaptiveWifiHelper.xcodeproj
```

Then press `⌘R` in Xcode to build and run.

## Usage

1. Launch `CaptiveWifiHelper.app` — it will appear in your menu bar (no Dock icon)
2. Click the menu bar icon to see the current status
3. When a captive portal is detected:
   - Click **Open Login Page** to open the login page in your browser
   - If the login page doesn't appear, click **Reconnect Wi-Fi** to disconnect and let macOS auto-join again
   - Click **Open Wi-Fi Settings…** to manage your network manually
4. Click **Check Now** to run an immediate connectivity check

## How It Works

The app uses two layers of detection:

1. **`NWPathMonitor`** — watches the system's network path for status changes (satisfied / requires connection / unsatisfied) with a 1-second debounce
2. **HTTP probe** — every 60 seconds (and on every path change) it fetches `http://captive.apple.com/hotspot-detect.html` and checks whether the response contains `"Success"`. A redirect or unexpected body indicates a captive portal is intercepting traffic.

## Permissions

The app uses `CoreWLAN` to disconnect Wi-Fi. macOS may prompt for permission the first time you use the **Reconnect Wi-Fi** feature.

## License

MIT License — see [LICENSE](LICENSE) for details.
