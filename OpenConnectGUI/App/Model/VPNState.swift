import Foundation

enum VPNState: Equatable {
    case disconnected
    case connecting(profile: VPNProfile)
    case connected(profile: VPNProfile, since: Date)
    case error(message: String)

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }

    var isConnecting: Bool {
        if case .connecting = self { return true }
        return false
    }

    var displayString: String {
        switch self {
        case .disconnected:
            return "Отключено"
        case .connecting(let profile):
            return "Подключение к \(profile.name)..."
        case .connected(let profile, let since):
            let duration = formatDuration(from: since)
            return "Подключено: \(profile.name) (\(duration))"
        case .error(let message):
            return "Ошибка: \(message)"
        }
    }

    private func formatDuration(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
