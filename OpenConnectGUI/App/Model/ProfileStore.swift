import Foundation
import Combine

class ProfileStore: ObservableObject {
    @Published var profiles: [VPNProfile] = []

    private let key = "vpn_profiles"

    init() {
        load()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([VPNProfile].self, from: data)
        else { return }
        profiles = decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func add(_ profile: VPNProfile) {
        profiles.append(profile)
        save()
    }

    func update(_ profile: VPNProfile) {
        if let idx = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[idx] = profile
            save()
        }
    }

    func delete(at offsets: IndexSet) {
        profiles.remove(atOffsets: offsets)
        save()
    }

    func delete(_ profile: VPNProfile) {
        profiles.removeAll { $0.id == profile.id }
        save()
    }
}
