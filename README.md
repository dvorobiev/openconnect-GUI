# OpenConnect VPN for macOS

A native macOS menu bar app for managing OpenConnect VPN connections. Built with Swift and SwiftUI, no Electron, no bloat.

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Menu bar app** — lives in your menu bar, out of your Dock
- **Multiple profiles** — manage as many VPN configurations as you need
- **Secure storage** — passwords stored in macOS Keychain, never in plain text
- **Protocol support** — Cisco AnyConnect, GlobalProtect, Juniper Network Connect, Pulse Secure
- **One-click connect** — pick a profile from the menu and go
- **Live status** — connection duration timer updates in real time
- **No dependencies** — pure Swift, uses only Apple frameworks

## Requirements

- macOS 13.0 Ventura or later
- [openconnect](https://www.infradead.org/openconnect/) installed via Homebrew:

```bash
brew install openconnect
```

## Installation

### Download

Grab the latest `.dmg` from [Releases](https://github.com/dvorobiev/openconnect-GUI/releases).

### Build from source

```bash
git clone https://github.com/dvorobiev/openconnect-GUI.git
cd openconnect-GUI
open OpenConnectGUI.xcodeproj
```

Build and run with `⌘ + R`.

## Setup

### 1. Configure openconnect path

On first launch, open **Preferences** from the menu bar icon and verify the path to `openconnect`. Default is `/opt/homebrew/bin/openconnect`.

### 2. Configure passwordless sudo (one-time)

OpenConnect requires root privileges to configure network interfaces. The app can set this up automatically:

1. Open **Preferences**
2. Click **Configure Privileges**
3. Enter your admin password when prompted

This creates `/etc/sudoers.d/openconnect-gui` allowing the app to run `openconnect` via `sudo` without a password prompt each time.

### 3. Add a VPN profile

1. Click the menu bar icon → **Profiles...**
2. Click **+** to add a new profile
3. Fill in name, server, username, and password
4. Optionally select protocol and configure advanced options

## Usage

Click the menu bar icon:

- **Connect** → select a profile from the submenu
- **Disconnect** — terminates the active connection
- **Profiles...** — manage your VPN profiles
- **Preferences...** — configure openconnect path and sudo

The icon changes to reflect connection state.

## Advanced

### Custom openconnect arguments

Each profile supports extra command-line arguments passed directly to `openconnect`. Useful for things like `--no-dtls`, `--servercert`, certificate paths, etc.

### Authentication groups

Some VPN servers require selecting an auth group at login. You can pre-configure it per profile so it's selected automatically.

### DNS configuration

If `/opt/homebrew/etc/vpnc/vpnc-script` is present, it is used automatically for DNS configuration on connect/disconnect.

## Architecture

```
OpenConnectGUI/
├── App/
│   ├── AppDelegate.swift          # App lifecycle
│   ├── StatusBarController.swift  # Menu bar icon and menu
│   ├── MenuBuilder.swift          # Menu construction
│   ├── Model/
│   │   ├── VPNProfile.swift       # Profile data model
│   │   ├── VPNState.swift         # Connection state enum
│   │   └── ProfileStore.swift     # Profile persistence
│   ├── Services/
│   │   ├── VPNManager.swift       # openconnect process management
│   │   ├── KeychainManager.swift  # Keychain read/write
│   │   └── SudoersSetup.swift     # Sudoers configuration
│   └── UI/
│       ├── ProfileListView.swift  # Profile list
│       ├── ProfileEditorView.swift # Add / edit profile
│       ├── PreferencesView.swift  # App preferences
│       └── WindowManager.swift    # Floating panel management
└── Resources/
    └── Info.plist
```

**Stack:** SwiftUI + AppKit, Combine, async/await, Security framework (Keychain).
No third-party dependencies.

## Contributing

Pull requests are welcome. For major changes, open an issue first.

## License

MIT
