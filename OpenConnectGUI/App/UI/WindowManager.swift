import AppKit
import SwiftUI

@MainActor
class WindowManager {
    static let shared = WindowManager()
    private init() {}

    private var profilesWindow: NSPanel?
    private var preferencesWindow: NSPanel?

    func showProfiles(profileStore: ProfileStore) {
        if let w = profilesWindow, w.isVisible {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let view = ProfileListView(store: profileStore)
        let panel = makePanel(title: "Профили VPN", content: AnyView(view), size: CGSize(width: 480, height: 400))
        profilesWindow = panel
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showPreferences() {
        if let w = preferencesWindow, w.isVisible {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let view = PreferencesView()
        let panel = makePanel(title: "Настройки", content: AnyView(view), size: CGSize(width: 480, height: 300))
        preferencesWindow = panel
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makePanel(title: String, content: AnyView, size: CGSize) -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .resizable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = title
        panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(rootView: content)
        panel.center()
        panel.level = .floating
        return panel
    }
}
