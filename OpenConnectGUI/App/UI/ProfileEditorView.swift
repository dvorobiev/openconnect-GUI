import SwiftUI

struct ProfileEditorView: View {
    @State var profile: VPNProfile
    @State private var password: String = ""
    let isNew: Bool
    let onSave: (VPNProfile, String) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(isNew ? "Новый профиль" : "Изменить профиль")
                .font(.headline)
                .padding()

            Divider()

            Form {
                Section("Основное") {
                    TextField("Название", text: $profile.name)
                    TextField("Сервер (vpn.example.com)", text: $profile.server)
                    TextField("Имя пользователя", text: $profile.username)
                    SecureField("Пароль", text: $password)
                        .onAppear {
                            if !isNew {
                                password = (try? KeychainManager.load(for: profile.id)) ?? ""
                            }
                        }
                }

                Section("Дополнительно") {
                    Picker("Протокол", selection: $profile.vpnProtocol) {
                        ForEach(VPNProtocol.allCases, id: \.self) { proto in
                            Text(proto.displayName).tag(proto)
                        }
                    }
                    TextField("Auth Group (если нужен)", text: $profile.authGroup)
                    TextField("Доп. аргументы (через пробел)", text: Binding(
                        get: { profile.extraArgs.joined(separator: " ") },
                        set: { profile.extraArgs = $0.components(separatedBy: " ").filter { !$0.isEmpty } }
                    ))
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Button("Отмена", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Сохранить") {
                    onSave(profile, password)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(profile.name.isEmpty || profile.server.isEmpty || profile.username.isEmpty)
            }
            .padding()
        }
        .frame(width: 480)
    }
}
