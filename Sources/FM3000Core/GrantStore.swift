import Foundation
import Security

/// Keeps the grant `{ at, homeKey, deviceId, kind }` between launches.
public protocol GrantStore {
    func load() -> Grant?
    func save(_ grant: Grant) throws
    func clear()
}

public final class MemoryGrantStore: GrantStore {
    private var grant: Grant?
    public init(_ grant: Grant? = nil) { self.grant = grant }
    public func load() -> Grant? { grant }
    public func save(_ grant: Grant) throws { self.grant = grant }
    public func clear() { grant = nil }
}

/// A JSON file, 0600: for the command line probe, which has no app keychain.
public final class FileGrantStore: GrantStore {
    private let url: URL
    public init(url: URL) { self.url = url }
    public func load() -> Grant? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Grant.self, from: data)
    }
    public func save(_ grant: Grant) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(grant).write(to: url, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }
    public func clear() { try? FileManager.default.removeItem(at: url) }
}

/// The app's grant in the iOS Keychain, readable after the first unlock so a restart can reconnect.
public final class KeychainGrantStore: GrantStore {
    private let service: String
    public init(service: String = "ai.tasman.fm3000.grant") { self.service = service }

    private var base: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: "grant"]
    }

    public func load() -> Grant? {
        var query = base
        query[kSecReturnData as String] = true
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess, let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(Grant.self, from: data)
    }

    public func save(_ grant: Grant) throws {
        clear()
        var query = base
        query[kSecValueData as String] = try JSONEncoder().encode(grant)
        #if os(iOS)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        #endif
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError(status: status, doing: "keeping the pairing") }
    }

    public func clear() { SecItemDelete(base as CFDictionary) }
}
