import SwiftUI

struct PreferencesView: View {
    @AppStorage("openconnect_path") private var openconnectPath = "/opt/homebrew/bin/openconnect"
    @State private var setupStatus: SetupStatus = .idle
    @State private var sudoersExists = SudoersSetup.isConfigured

    enum SetupStatus: Equatable {
        case idle, working, success, failure(String)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("Путь к openconnect") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField("/opt/homebrew/bin/openconnect", text: $openconnectPath)
                            .textFieldStyle(.roundedBorder)
                        Button("Найти...") { chooseOpenconnect() }
                    }

                    if !FileManager.default.fileExists(atPath: openconnectPath) {
                        Label("Файл не найден", systemImage: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .font(.caption)
                    } else {
                        Label("Найден", systemImage: "checkmark.circle")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                .padding(8)
            }

            GroupBox("Привилегии (sudo)") {
                VStack(alignment: .leading, spacing: 8) {
                    if sudoersExists {
                        Label("sudoers настроен (\(SudoersSetup.sudoersFile))", systemImage: "checkmark.shield")
                            .foregroundColor(.green)
                    } else {
                        Label("sudoers не настроен — openconnect не сможет запуститься", systemImage: "shield.slash")
                            .foregroundColor(.orange)
                    }

                    Button {
                        configureSudoers()
                    } label: {
                        switch setupStatus {
                        case .idle:
                            Label("Настроить доступ к openconnect (один раз)", systemImage: "lock.shield")
                        case .working:
                            Label("Настройка...", systemImage: "arrow.triangle.2.circlepath")
                        case .success:
                            Label("Успешно настроено!", systemImage: "checkmark.circle")
                        case .failure(let msg):
                            Label("Ошибка: \(msg)", systemImage: "xmark.circle")
                        }
                    }
                    .disabled(setupStatus == .working)
                }
                .padding(8)
            }

            Spacer()

            Text("Настройка sudoers требует пароль администратора один раз.\nПосле этого VPN будет запускаться без дополнительных запросов.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 460, height: 280)
    }

    private func chooseOpenconnect() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/opt/homebrew/bin")
        if panel.runModal() == .OK, let url = panel.url {
            openconnectPath = url.path
        }
    }

    private func configureSudoers() {
        setupStatus = .working
        Task {
            do {
                try SudoersSetup.configure(openconnectPath: openconnectPath)
                await MainActor.run {
                    setupStatus = .success
                    sudoersExists = true
                }
            } catch {
                await MainActor.run {
                    setupStatus = .failure(error.localizedDescription)
                }
            }
        }
    }
}
