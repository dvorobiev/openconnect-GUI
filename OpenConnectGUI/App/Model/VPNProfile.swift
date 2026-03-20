import Foundation

struct VPNProfile: Identifiable, Codable, Equatable {
    var id: UUID = .init()
    var name: String
    var server: String
    var username: String
    var vpnProtocol: VPNProtocol = .anyconnect
    var authGroup: String = ""
    var extraArgs: [String] = []
    // Пароль хранится только в Keychain по id.uuidString
}

enum VPNProtocol: String, Codable, CaseIterable {
    case anyconnect
    case gp
    case nc
    case pulse

    var displayName: String {
        switch self {
        case .anyconnect: return "AnyConnect"
        case .gp:         return "GlobalProtect"
        case .nc:         return "Juniper Network Connect"
        case .pulse:      return "Pulse"
        }
    }
}
