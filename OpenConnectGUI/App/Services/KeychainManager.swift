import Foundation
import Security

enum KeychainError: LocalizedError {
    case unhandledError(status: OSStatus)
    case unexpectedData
    case itemNotFound

    var errorDescription: String? {
        switch self {
        case .unhandledError(let status):
            return "Keychain error: \(status)"
        case .unexpectedData:
            return "Unexpected data format in Keychain"
        case .itemNotFound:
            return "Item not found in Keychain"
        }
    }
}

struct KeychainManager {
    static let service = "com.openconnect.gui"

    static func save(password: String, for profileID: UUID) throws {
        let data = Data(password.utf8)
        let account = profileID.uuidString

        // Попробуем обновить существующую запись
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        let attributes: [CFString: Any] = [kSecValueData: data]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if updateStatus == errSecItemNotFound {
            // Элемента нет — добавляем
            var addQuery = query
            addQuery[kSecValueData] = data
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unhandledError(status: addStatus)
            }
        } else if updateStatus != errSecSuccess {
            throw KeychainError.unhandledError(status: updateStatus)
        }
    }

    static func load(for profileID: UUID) throws -> String {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: profileID.uuidString,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unhandledError(status: status)
        }

        guard let data = result as? Data, let password = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        return password
    }

    static func delete(for profileID: UUID) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: profileID.uuidString
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
}
