import SwiftUI

@main
struct OpenConnectGUIApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Сцена пустая — всё управление через NSStatusItem в AppDelegate
        Settings {
            EmptyView()
        }
    }
}
