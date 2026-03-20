import AppKit

@MainActor
struct MenuBuilder {
    static func build(
        state: VPNState,
        profiles: [VPNProfile],
        onConnect: @escaping @MainActor (VPNProfile) -> Void,
        onDisconnect: @escaping @MainActor () -> Void,
        onProfiles: @escaping @MainActor () -> Void,
        onPreferences: @escaping @MainActor () -> Void,
        onQuit: @escaping @MainActor () -> Void
    ) -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        // Статус
        let statusItem = NSMenuItem(title: state.displayString, action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)
        menu.addItem(.separator())

        // Подключить → подменю
        if !profiles.isEmpty && !state.isConnected && !state.isConnecting {
            let connectItem = NSMenuItem(title: "Подключить", action: nil, keyEquivalent: "")
            let submenu = NSMenu()
            for profile in profiles {
                let item = MenuItem(title: profile.name) { onConnect(profile) }
                submenu.addItem(item)
            }
            connectItem.submenu = submenu
            menu.addItem(connectItem)
        }

        // Отключить
        let disconnectItem = MenuItem(title: "Отключить") { onDisconnect() }
        disconnectItem.isEnabled = state.isConnected || state.isConnecting
        menu.addItem(disconnectItem)

        menu.addItem(.separator())

        // Профили
        menu.addItem(MenuItem(title: "Профили...") { onProfiles() })

        // Настройки
        menu.addItem(MenuItem(title: "Настройки...") { onPreferences() })

        menu.addItem(.separator())

        // Выйти
        menu.addItem(MenuItem(title: "Выйти") { onQuit() })

        return menu
    }
}

// MARK: - Вспомогательный класс для closure-based menu items

@MainActor
final class MenuItem: NSMenuItem {
    private var handler: @MainActor () -> Void

    init(title: String, action: @escaping @MainActor () -> Void) {
        self.handler = action
        super.init(title: title, action: #selector(performAction), keyEquivalent: "")
        self.target = self
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func performAction() {
        MainActor.assumeIsolated {
            handler()
        }
    }
}
