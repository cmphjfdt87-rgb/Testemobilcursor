import Foundation

/// Live telemetry decoded from the scooter. All values are optional because
/// they are populated as the corresponding registers are read over BLE.
struct ScooterState: Equatable {
    var serialNumber: String?
    var firmwareVersion: String?
    var bleVersion: String?

    var batteryPercent: Int?
    var batteryVoltage: Double?      // volts
    var batteryCurrent: Double?      // amps (negative = charging)
    var batteryTemperature: Int?     // °C

    var speed: Double?               // km/h
    var averageSpeed: Double?        // km/h
    var totalDistance: Double?       // km
    var tripDistance: Double?        // km
    var operatingTime: Int?          // seconds

    var controllerTemperature: Int?  // °C

    var region: ScooterRegion?
    var speedLimit: Int?             // km/h, current firmware speed cap
    var cruiseControlEnabled: Bool?
    var tailLightEnabled: Bool?
    var krystenLockEnabled: Bool?
}

/// Identifies the connected hardware family so the protocol layer can pick the
/// correct register map and encryption scheme.
enum ScooterModel: String, CaseIterable, Identifiable {
    case m365 = "Xiaomi M365 / 1S / Pro / Pro 2"
    case ninebotES = "Ninebot ES1 / ES2 / ES4"
    case ninebotMax = "Ninebot Max G30"
    case ninebotF = "Ninebot F-series (F20/F25/F30/F40)"
    case ninebotG2 = "Ninebot Max G2 / GT"
    case unknown = "Inconnu"

    var id: String { rawValue }

    /// Whether this family wraps its payloads in AES encryption.
    /// Older M365/ES use plaintext; Max G30 and newer use the encrypted
    /// Ninebot protocol.
    var usesEncryption: Bool {
        switch self {
        case .m365, .ninebotES: return false
        case .ninebotMax, .ninebotF, .ninebotG2, .unknown: return true
        }
    }
}
