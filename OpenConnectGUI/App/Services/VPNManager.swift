import Foundation
import Combine

@MainActor
class VPNManager: ObservableObject {
    @Published private(set) var state: VPNState = .disconnected

    private var process: Process?
    private var outputTask: Task<Void, Never>?
    private var monitorTask: Task<Void, Never>?

    var openconnectPath: String {
        UserDefaults.standard.string(forKey: "openconnect_path") ?? "/opt/homebrew/bin/openconnect"
    }

    // MARK: - Connect

    func connect(profile: VPNProfile) async {
        guard case .disconnected = state, !(state.isConnecting) else { return }

        // Получаем пароль из Keychain
        let password: String
        do {
            password = try KeychainManager.load(for: profile.id)
        } catch {
            state = .error(message: "Не удалось получить пароль из Keychain: \(error.localizedDescription)")
            return
        }

        state = .connecting(profile: profile)

        do {
            try await startProcess(profile: profile, password: password)
        } catch {
            state = .error(message: error.localizedDescription)
        }
    }

    private func startProcess(profile: VPNProfile, password: String) async throws {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")

        // Явно указываем vpnc-script от Homebrew — без него openconnect
        // не может настроить DNS через networksetup и падает
        let vpncScript = "/opt/homebrew/etc/vpnc/vpnc-script"
        let scriptArg = FileManager.default.fileExists(atPath: vpncScript)
            ? "--script=\(vpncScript)"
            : "--no-script"

        var args = ["-n", openconnectPath,
                    "--user=\(profile.username)",
                    "--passwd-on-stdin",
                    "--non-inter",
                    "--protocol=\(profile.vpnProtocol.rawValue)",
                    scriptArg]

        if !profile.authGroup.isEmpty {
            args += ["--authgroup=\(profile.authGroup)"]
        }
        args += profile.extraArgs
        args.append(profile.server)

        proc.arguments = args

        let stdinPipe = Pipe()
        let outPipe = Pipe()
        proc.standardInput = stdinPipe
        proc.standardOutput = outPipe
        proc.standardError = outPipe

        proc.terminationHandler = { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleTermination()
            }
        }

        try proc.run()
        self.process = proc

        // Отправляем пароль
        let passwordData = Data((password + "\n").utf8)
        try stdinPipe.fileHandleForWriting.write(contentsOf: passwordData)
        try stdinPipe.fileHandleForWriting.close()

        // Мониторим вывод
        startOutputMonitoring(pipe: outPipe, profile: profile)
    }

    // MARK: - Output monitoring

    private func startOutputMonitoring(pipe: Pipe, profile: VPNProfile) {
        let fileHandle = pipe.fileHandleForReading
        outputTask = Task { [weak self] in
            for await line in fileHandle.lines() {
                await MainActor.run {
                    self?.processOutputLine(line, profile: profile)
                }
            }
        }
    }

    private func processOutputLine(_ line: String, profile: VPNProfile) {
        NSLog("[openconnect] \(line)")

        // Триггеры успешного подключения
        // "Got CONNECT response: HTTP/1.1 200 CONNECTED" или "Configured as X.X.X.X"
        if line.contains("Got CONNECT response") ||
           line.contains("Configured as") ||
           line.contains("Established DTLS") ||
           line.contains("Established TLS") {
            if case .connecting = state {
                state = .connected(profile: profile, since: Date())
            }
        }
        // Триггеры ошибок — только если ещё не подключились
        else if line.contains("Server has disconnected") ||
                line.contains("Connect attempt was rejected") ||
                line.contains("Failed to connect") ||
                line.contains("AUTH_FAILED") {
            if !state.isConnected {
                state = .error(message: line)
            }
        }
    }

    // MARK: - Disconnect

    func disconnect() {
        outputTask?.cancel()
        outputTask = nil
        process?.terminate()
        process = nil
        state = .disconnected
    }

    private func handleTermination() {
        outputTask?.cancel()
        outputTask = nil
        process = nil
        if case .connected = state {
            state = .disconnected
        } else if case .connecting = state {
            state = .error(message: "openconnect завершился неожиданно")
        }
    }

    deinit {
        process?.terminate()
    }
}

// MARK: - FileHandle async lines

private extension FileHandle {
    func lines() -> AsyncStream<String> {
        AsyncStream { continuation in
            let notifCenter = NotificationCenter.default
            let handle = notifCenter.addObserver(
                forName: .NSFileHandleDataAvailable,
                object: self,
                queue: nil
            ) { [weak self] _ in
                guard let self = self else { return }
                let data = self.availableData
                if data.isEmpty {
                    continuation.finish()
                    return
                }
                if let text = String(data: data, encoding: .utf8) {
                    for line in text.components(separatedBy: .newlines) where !line.isEmpty {
                        continuation.yield(line)
                    }
                }
                self.waitForDataInBackgroundAndNotify()
            }
            self.waitForDataInBackgroundAndNotify()
            continuation.onTermination = { _ in
                notifCenter.removeObserver(handle)
            }
        }
    }
}
