import SwiftUI

struct EditTarget: Identifiable {
    let profile: VPNProfile
    let isNew: Bool
    var id: UUID { profile.id }
}

struct ProfileListView: View {
    @ObservedObject var store: ProfileStore
    @State private var editTarget: EditTarget?

    var body: some View {
        VStack(spacing: 0) {
            if store.profiles.isEmpty {
                Spacer()
                Text("Нет профилей")
                    .foregroundColor(.secondary)
                Text("Нажмите «+» чтобы добавить")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                List {
                    ForEach(store.profiles) { profile in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.name).fontWeight(.medium)
                                Text("\(profile.username)@\(profile.server)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Изменить") {
                                editTarget = EditTarget(profile: profile, isNew: false)
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { offsets in
                        for idx in offsets {
                            let profile = store.profiles[idx]
                            try? KeychainManager.delete(for: profile.id)
                        }
                        store.delete(at: offsets)
                    }
                }
            }

            Divider()

            HStack {
                Button {
                    editTarget = EditTarget(profile: VPNProfile(name: "", server: "", username: ""), isNew: true)
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .padding(8)
                Spacer()
            }
        }
        .sheet(item: $editTarget) { target in
            ProfileEditorView(
                profile: target.profile,
                isNew: target.isNew,
                onSave: { updated, password in
                    if target.isNew {
                        store.add(updated)
                    } else {
                        store.update(updated)
                    }
                    if !password.isEmpty {
                        try? KeychainManager.save(password: password, for: updated.id)
                    }
                    editTarget = nil
                },
                onCancel: { editTarget = nil }
            )
        }
    }
}
