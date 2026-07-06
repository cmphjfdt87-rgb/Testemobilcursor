import Foundation

/// Firmware region / market. On Ninebot & Xiaomi scooters the region byte
/// controls the default speed cap, display units and legal-mode behaviour.
///
/// NOTE: the exact register value per model must be confirmed against the
/// firmware you are running. The values below are the community-documented
/// defaults for the M365/Ninebot register `0x72` (KERS/region block). Treat
/// them as a starting point, not gospel — see `NinebotRegisters`.
enum ScooterRegion: UInt8, CaseIterable, Identifiable {
    case global = 0x00      // No hard cap beyond model max
    case unitedStates = 0x01
    case europe = 0x02      // 25 km/h legal cap (EN 17128)
    case china = 0x03       // 25 km/h, km display

    var id: UInt8 { rawValue }

    var displayName: String {
        switch self {
        case .global: return "Global / Déverrouillé"
        case .unitedStates: return "États-Unis"
        case .europe: return "Europe (25 km/h)"
        case .china: return "Chine (25 km/h)"
        }
    }

    var flagEmoji: String {
        switch self {
        case .global: return "🌍"
        case .unitedStates: return "🇺🇸"
        case .europe: return "🇪🇺"
        case .china: return "🇨🇳"
        }
    }

    /// Human-readable note about the typical speed behaviour of this region.
    var speedNote: String {
        switch self {
        case .global: return "Vitesse maximale selon le matériel (débridé)."
        case .unitedStates: return "Plafond typique 32 km/h (20 mph)."
        case .europe: return "Plafond légal 25 km/h."
        case .china: return "Plafond légal 25 km/h, affichage en km."
        }
    }
}
