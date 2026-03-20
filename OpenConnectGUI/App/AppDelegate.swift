import AppKit

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private let vpnManager = VPNManager()
    private let profileStore = ProfileStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Скрываем из Dock (LSUIElement=YES в Info.plist должно это делать,
        // но для надёжности продублируем)
        NSApp.setActivationPolicy(.accessory)

        statusBarController = StatusBarController(
            vpnManager: vpnManager,
            profileStore: profileStore
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        vpnManager.disconnect()
    }
}
