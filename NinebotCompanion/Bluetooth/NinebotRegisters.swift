import Foundation

/// Register (memory) addresses used by the Xiaomi/Ninebot serial protocol.
///
/// These are the addresses published by the open-source scooter community
/// (m365 / ScooterHacking projects). They are stable across the M365/Pro/ES
/// families but SOME addresses moved on the Max G30 and later encrypted
/// firmwares. Always verify with a read before writing on an unknown model.
enum NinebotRegisters {
    // Device identity
    static let serialNumber: UInt8   = 0x10   // 14 bytes ASCII
    static let firmwareVersion: UInt8 = 0x1A  // 2 bytes
    static let bleVersion: UInt8      = 0x1B  // 2 bytes

    // Live telemetry
    static let batteryPercent: UInt8  = 0x32  // 2 bytes
    static let batteryVoltage: UInt8  = 0x34  // 2 bytes, /100 V
    static let batteryCurrent: UInt8  = 0x33  // 2 bytes signed, /100 A
    static let speed: UInt8           = 0xB5  // 2 bytes signed, /1000 km/h
    static let averageSpeed: UInt8    = 0xB2  // 2 bytes
    static let totalMileage: UInt8    = 0x29  // 4 bytes, /1000 km
    static let tripMileage: UInt8     = 0xB9  // 2 bytes, /100 km
    static let operatingTime: UInt8   = 0x3A  // 4 bytes, seconds
    static let controllerTemp: UInt8  = 0x3E  // 2 bytes, /10 °C

    // Configuration / tuning
    static let region: UInt8          = 0x72  // 1 byte, see ScooterRegion
    static let speedLimit: UInt8      = 0x74  // 2 bytes, km/h (drive/eco caps)
    static let cruiseControl: UInt8   = 0x7C  // 1 byte, 0/1
    static let tailLight: UInt8       = 0x7D  // 1 byte, 0/1
    static let krystenLock: UInt8     = 0x70  // 1 byte, 0/1
}

/// Bus addresses (the "who" of each packet).
enum NinebotAddress {
    static let app: UInt8  = 0x3D   // this phone / BLE client
    static let esc: UInt8  = 0x20   // motor controller (ESC)
    static let bms: UInt8  = 0x22   // battery management system
    static let ble: UInt8  = 0x21   // on-board BLE chip
}

/// Command opcodes.
enum NinebotCommand {
    static let read: UInt8  = 0x01
    static let write: UInt8 = 0x03
}
