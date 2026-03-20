import AppKit
import Combine

@MainActor
class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private let vpnManager: VPNManager
    private let profileStore: ProfileStore
    private var cancellables = Set<AnyCancellable>()
    private var pollingTask: Task<Void, Never>?

    init(vpnManager: VPNManager, profileStore: ProfileStore) {
        self.vpnManager = vpnManager
        self.profileStore = profileStore
        super.init()
        setupStatusItem()
        bindState()
        startPolling()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateIcon(for: .disconnected)
        statusItem.button?.target = self
    }

    private func bindState() {
        vpnManager.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.updateIcon(for: state)
                self?.rebuildMenu()
            }
            .store(in: &cancellables)

        profileStore.$profiles
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.rebuildMenu()
            }
            .store(in: &cancellables)
    }

    // MARK: - Polling (обновление таймера в статусе)

    private func startPolling() {
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                await MainActor.run {
                    self?.rebuildMenu()
                }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    // MARK: - Icon

    private func updateIcon(for state: VPNState) {
        let imageName: String
        switch state {
        case .disconnected, .error:
            imageName = "vpn-off"
        case .connecting:
            imageName = "vpn-connecting"
        case .connected:
            imageName = "vpn-on"
        }

        if let image = NSImage(named: imageName) {
            image.isTemplate = true
            statusItem.button?.image = image
        } else {
            // Fallback: системные символы
            let sfsymbol: String
            switch state {
            case .disconnected, .error: sfsymbol = "lock.slash"
            case .connecting:           sfsymbol = "arrow.triangle.2.circlepath"
            case .connected:            sfsymbol = "lock.fill"
            }
            statusItem.button?.image = NSImage(systemSymbolName: sfsymbol, accessibilityDescription: nil)
        }
    }

    // MARK: - Menu

    func rebuildMenu() {
        let menu = MenuBuilder.build(
            state: vpnManager.state,
            profiles: profileStore.profiles,
            onConnect: { [weak self] profile in
                Task { await self?.vpnManager.connect(profile: profile) }
            },
            onDisconnect: { [weak self] in
                self?.vpnManager.disconnect()
            },
            onProfiles: { [weak self] in
                self?.openProfiles()
            },
            onPreferences: { [weak self] in
                self?.openPreferences()
            },
            onQuit: {
                NSApplication.shared.terminate(nil)
            }
        )
        statusItem.menu = menu
    }

    // MARK: - Windows

    private func openProfiles() {
        WindowManager.shared.showProfiles(profileStore: profileStore)
    }

    private func openPreferences() {
        WindowManager.shared.showPreferences()
    }
}
