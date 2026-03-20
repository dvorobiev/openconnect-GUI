import Foundation

enum SudoersSetupError: LocalizedError {
    case appleScriptFailed(String)
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .appleScriptFailed(let msg):
            return "AppleScript ошибка: \(msg)"
        case .verificationFailed:
            return "Настройка sudoers завершилась, но проверка sudo -n не прошла"
        }
    }
}

struct SudoersSetup {
    static let sudoersFile = "/etc/sudoers.d/openconnect-gui"

    /// Записывает sudoers-файл с правом запускать openconnect без пароля.
    /// Использует AppleScript для получения прав администратора.
    static func configure(openconnectPath: String) throws {
        // Экранируем одиночные кавычки в пути
        let safePath = openconnectPath.replacingOccurrences(of: "'", with: "'\\''")
        let content = "%admin ALL=(ALL) NOPASSWD: \(safePath)"

        let shellCommand = """
        echo '\(content)' > \(sudoersFile) && chmod 440 \(sudoersFile) && visudo -c -f \(sudoersFile)
        """

        let appleScript = """
        do shell script "\(shellCommand.replacingOccurrences(of: "\"", with: "\\\""))" with administrator privileges
        """

        var error: NSDictionary?
        let script = NSAppleScript(source: appleScript)
        script?.executeAndReturnError(&error)

        if let err = error {
            let msg = (err[NSAppleScript.errorMessage] as? String) ?? "Unknown error"
            throw SudoersSetupError.appleScriptFailed(msg)
        }

        // Верификация: sudo -n dry run
        guard verifySudo(openconnectPath: openconnectPath) else {
            throw SudoersSetupError.verificationFailed
        }
    }

    /// Проверяет, работает ли sudo -n для openconnect.
    static func verifySudo(openconnectPath: String) -> Bool {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        proc.arguments = ["-n", "-l", openconnectPath]
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice
        try? proc.run()
        proc.waitUntilExit()
        return proc.terminationStatus == 0
    }

    /// Возвращает true если sudoers-файл существует.
    static var isConfigured: Bool {
        FileManager.default.fileExists(atPath: sudoersFile)
    }
}
