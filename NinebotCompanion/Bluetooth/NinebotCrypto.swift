import Foundation
import CryptoKit

/// Payload encryption for the newer Ninebot families (Max G30, F-series, G2…).
///
/// ⚠️ IMPORTANT / HONEST STATUS ⚠️
/// -------------------------------------------------------------------------
/// Older Xiaomi/Ninebot scooters (M365, 1S, Pro, ES) speak the protocol in
/// PLAINTEXT — `passthrough` handles those and it works.
///
/// Newer firmwares wrap each payload in an AES-based scheme whose session key
/// is negotiated during the BLE handshake. That handshake and key schedule
/// differ per firmware and are NOT reproduced here, because:
///   • there is no single scheme that covers "all Ninebot / all firmware", and
///   • shipping guessed crypto would silently corrupt writes and could brick
///     a controller.
///
/// This type therefore exposes a clean seam: implement `encrypt`/`decrypt`
/// for the model you have verified, register it in `BluetoothManager`, and the
/// rest of the app works unchanged. `AESPlaceholderCrypto` documents where the
/// AES-CBC/session-key logic belongs.
/// -------------------------------------------------------------------------
protocol NinebotCrypto {
    func encrypt(_ payload: [UInt8]) throws -> [UInt8]
    func decrypt(_ payload: [UInt8]) throws -> [UInt8]
}

enum CryptoError: Error { case notImplemented }

/// Used by plaintext families — no transformation.
struct PassthroughCrypto: NinebotCrypto {
    func encrypt(_ payload: [UInt8]) throws -> [UInt8] { payload }
    func decrypt(_ payload: [UInt8]) throws -> [UInt8] { payload }
}

/// Scaffold for the encrypted families. The BLE handshake must first establish
/// `sessionKey`; then payloads are AES-encrypted per the firmware's scheme.
///
/// Fill in `encrypt`/`decrypt` once you have verified the exact mode
/// (CBC/CTR), IV derivation and MAC for your target model. The helper below
/// shows an AES-CBC example so the wiring is obvious — it is intentionally
/// guarded so it can't run against real hardware until you enable it.
struct AESPlaceholderCrypto: NinebotCrypto {
    let sessionKey: SymmetricKey?
    var enabled: Bool = false

    func encrypt(_ payload: [UInt8]) throws -> [UInt8] {
        guard enabled, let _ = sessionKey else { throw CryptoError.notImplemented }
        // TODO: implement the verified AES scheme for the target firmware.
        throw CryptoError.notImplemented
    }

    func decrypt(_ payload: [UInt8]) throws -> [UInt8] {
        guard enabled, let _ = sessionKey else { throw CryptoError.notImplemented }
        // TODO: implement the verified AES scheme for the target firmware.
        throw CryptoError.notImplemented
    }
}
