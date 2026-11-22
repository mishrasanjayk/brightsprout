import Foundation
import Security

/// A 4-digit parent PIN kept in the iPhone Keychain (not in the web app's storage),
/// so a child can't give themselves more screen time.
enum ParentPin {
    private static let service = "BrightSprout.ParentPIN"

    private static var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: "parent"]
    }

    static var isSet: Bool { read() != nil }

    static func check(_ pin: String) -> Bool { read() == pin }

    static func save(_ pin: String) {
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = Data(pin.utf8)
        add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
    }

    private static func read() -> String? {
        var q = query
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess,
              let data = out as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
