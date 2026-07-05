import Foundation

/// Builds and parses frames for the Xiaomi/Ninebot serial-over-BLE protocol.
///
/// Frame layout (plaintext families such as M365/Pro/ES):
///
///   ┌──────┬──────┬─────┬──────┬─────┬─────┬─────────┬──────────┐
///   │ 0x5A │ 0xA5 │ len │ dst  │ src │ cmd │ payload │ checksum │
///   └──────┴──────┴─────┴──────┴─────┴─────┴─────────┴──────────┘
///
/// `len` counts the bytes from `dst` up to (but not including) the checksum.
/// `checksum` is a 16-bit little-endian value: the one's complement of the
/// sum of every byte from `len` through the end of the payload.
///
/// Encrypted families (Max G30 and newer) reuse this framing but the payload
/// is wrapped by `NinebotCrypto`. See that type for the current status.
enum NinebotProtocol {

    static let header: [UInt8] = [0x5A, 0xA5]

    /// Build a read request for `length` bytes starting at `register`.
    static func readRequest(register: UInt8,
                            length: UInt8,
                            destination: UInt8 = NinebotAddress.esc) -> [UInt8] {
        // payload for a read = [register, length]
        buildFrame(destination: destination,
                  source: NinebotAddress.app,
                  command: NinebotCommand.read,
                  payload: [register, length])
    }

    /// Build a write request that stores `bytes` at `register`.
    static func writeRequest(register: UInt8,
                            bytes: [UInt8],
                            destination: UInt8 = NinebotAddress.esc) -> [UInt8] {
        buildFrame(destination: destination,
                  source: NinebotAddress.app,
                  command: NinebotCommand.write,
                  payload: [register] + bytes)
    }

    /// Assemble a complete frame including header, length and checksum.
    static func buildFrame(destination: UInt8,
                          source: UInt8,
                          command: UInt8,
                          payload: [UInt8]) -> [UInt8] {
        // body = everything the checksum & length cover: dst, src, cmd, payload
        let body: [UInt8] = [destination, source, command] + payload
        let len = UInt8(body.count)
        let checksummed: [UInt8] = [len] + body
        let checksum = checksum16(checksummed)

        return header
            + checksummed
            + [UInt8(checksum & 0xFF), UInt8((checksum >> 8) & 0xFF)]
    }

    /// 16-bit one's-complement checksum used by the protocol.
    static func checksum16(_ bytes: [UInt8]) -> UInt16 {
        var sum: UInt32 = 0
        for b in bytes { sum &+= UInt32(b) }
        return UInt16((~sum) & 0xFFFF)
    }

    // MARK: - Parsing

    struct Frame {
        let source: UInt8
        let destination: UInt8
        let command: UInt8
        let register: UInt8
        let payload: [UInt8]   // bytes after the register byte
    }

    /// Attempt to parse a single complete frame out of `data`.
    /// Returns nil if the buffer is incomplete or the checksum fails.
    static func parse(_ data: [UInt8]) -> Frame? {
        guard data.count >= 8 else { return nil }
        guard data[0] == header[0], data[1] == header[1] else { return nil }

        let len = Int(data[2])
        // header(2) + len(1) + body(len) + checksum(2)
        let total = 2 + 1 + len + 2
        guard data.count >= total else { return nil }

        let checksummed = Array(data[2..<(3 + len)])
        let expected = checksum16(checksummed)
        let actual = UInt16(data[3 + len]) | (UInt16(data[3 + len + 1]) << 8)
        guard expected == actual else { return nil }

        let dst = data[3]
        let src = data[4]
        let cmd = data[5]
        let register = data[6]
        let payload = Array(data[7..<(3 + len)])

        return Frame(source: src,
                    destination: dst,
                    command: cmd,
                    register: register,
                    payload: payload)
    }
}

// MARK: - Little-endian decoding helpers

extension Array where Element == UInt8 {
    var leUInt16: UInt16? {
        guard count >= 2 else { return nil }
        return UInt16(self[0]) | (UInt16(self[1]) << 8)
    }

    var leInt16: Int16? {
        guard let u = leUInt16 else { return nil }
        return Int16(bitPattern: u)
    }

    var leUInt32: UInt32? {
        guard count >= 4 else { return nil }
        return UInt32(self[0])
            | (UInt32(self[1]) << 8)
            | (UInt32(self[2]) << 16)
            | (UInt32(self[3]) << 24)
    }
}
