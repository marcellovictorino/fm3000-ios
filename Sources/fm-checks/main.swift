import FM3000Core
import Foundation
import Security
let dir = NSTemporaryDirectory() + "kc-\(UUID().uuidString)"
try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
let store = try KeychainIdentityStore(scratchKeychainPath: dir + "/s.keychain")
let a = try store.loadOrCreate()
let b = try store.loadOrCreate()
print(a.pin, b.pin)
