import Foundation
import CommonCrypto

/// Stringlerin SHA256 hash'inin alınması için extension
extension String {
    var sha256: String {
        let data = Data(self.utf8)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { bufferPtr in
            _ = CC_SHA256(bufferPtr.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
