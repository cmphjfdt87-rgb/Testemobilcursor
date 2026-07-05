import Foundation
import CoreBluetooth
import Combine

/// Represents a scooter discovered during a scan.
struct DiscoveredScooter: Identifiable, Equatable {
    let id: UUID
    let name: String
    let rssi: Int
    let peripheral: CBPeripheral

    static func == (lhs: DiscoveredScooter, rhs: DiscoveredScooter) -> Bool {
        lhs.id == rhs.id
    }
}

enum ConnectionState: Equatable {
    case poweredOff
    case idle
    case scanning
    case connecting
    case connected
    case failed(String)
}

/// Central controller for BLE discovery, connection and the read/write loop
/// against a Ninebot/Xiaomi scooter over the Nordic UART service.
final class BluetoothManager: NSObject, ObservableObject {

    // Nordic UART Service (NUS) — used by the M365/Ninebot BLE bridge.
    private let serviceUUID  = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    private let rxUUID       = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E") // write
    private let txUUID       = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E") // notify

    @Published private(set) var connectionState: ConnectionState = .idle
    @Published private(set) var discovered: [DiscoveredScooter] = []
    @Published private(set) var state = ScooterState()
    @Published var model: ScooterModel = .unknown
    @Published private(set) var log: [String] = []

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var writeChar: CBCharacteristic?
    private var rxBuffer: [UInt8] = []

    private var crypto: NinebotCrypto = PassthroughCrypto()
    private var pollTimer: Timer?

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: - Public API

    func startScan() {
        guard central.state == .poweredOn else {
            connectionState = .poweredOff
            return
        }
        discovered.removeAll()
        connectionState = .scanning
        // Scan broadly; scooters advertise custom names, filter by heuristic.
        central.scanForPeripherals(withServices: nil,
                                  options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        addLog("Recherche de trottinettes…")
    }

    func stopScan() {
        central.stopScan()
        if connectionState == .scanning { connectionState = .idle }
    }

    func connect(_ scooter: DiscoveredScooter) {
        stopScan()
        connectionState = .connecting
        peripheral = scooter.peripheral
        peripheral?.delegate = self
        central.connect(scooter.peripheral, options: nil)
        addLog("Connexion à \(scooter.name)…")
    }

    func disconnect() {
        pollTimer?.invalidate()
        if let p = peripheral { central.cancelPeripheralConnection(p) }
        peripheral = nil
        writeChar = nil
        connectionState = .idle
        state = ScooterState()
    }

    // MARK: - High level commands

    /// Write a new region byte, then read it back to confirm.
    func setRegion(_ region: ScooterRegion) {
        addLog("Écriture région → \(region.displayName)")
        write(register: NinebotRegisters.region, bytes: [region.rawValue])
        read(register: NinebotRegisters.region, length: 1)
    }

    /// Write the top speed limit (km/h) applied by the firmware.
    func setSpeedLimit(_ kmh: Int) {
        let clamped = UInt16(max(1, min(kmh, 100)))
        addLog("Écriture vitesse max → \(clamped) km/h")
        write(register: NinebotRegisters.speedLimit,
              bytes: [UInt8(clamped & 0xFF), UInt8(clamped >> 8)])
        read(register: NinebotRegisters.speedLimit, length: 2)
    }

    func setCruiseControl(_ on: Bool) {
        write(register: NinebotRegisters.cruiseControl, bytes: [on ? 1 : 0])
    }

    func setTailLight(_ on: Bool) {
        write(register: NinebotRegisters.tailLight, bytes: [on ? 1 : 0])
    }

    // MARK: - Register I/O

    func read(register: UInt8, length: UInt8) {
        let frame = NinebotProtocol.readRequest(register: register, length: length)
        send(frame)
    }

    func write(register: UInt8, bytes: [UInt8]) {
        let frame = NinebotProtocol.writeRequest(register: register, bytes: bytes)
        send(frame)
    }

    private func send(_ frame: [UInt8]) {
        guard let p = peripheral, let ch = writeChar else { return }
        do {
            let payload = try crypto.encrypt(frame)
            p.writeValue(Data(payload), for: ch, type: .withoutResponse)
        } catch {
            addLog("⚠️ Chiffrement requis mais non implémenté pour ce modèle.")
        }
    }

    /// Poll the common telemetry registers on a timer.
    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.refreshTelemetry()
        }
        // Fetch identity + config once on connect.
        read(register: NinebotRegisters.serialNumber, length: 14)
        read(register: NinebotRegisters.firmwareVersion, length: 2)
        read(register: NinebotRegisters.region, length: 1)
        read(register: NinebotRegisters.speedLimit, length: 2)
    }

    private func refreshTelemetry() {
        read(register: NinebotRegisters.batteryPercent, length: 2)
        read(register: NinebotRegisters.batteryVoltage, length: 2)
        read(register: NinebotRegisters.speed, length: 2)
        read(register: NinebotRegisters.totalMileage, length: 4)
        read(register: NinebotRegisters.controllerTemp, length: 2)
    }

    // MARK: - Frame handling

    private func handle(_ bytes: [UInt8]) {
        rxBuffer.append(contentsOf: bytes)
        // Try to peel off complete frames from the front of the buffer.
        while let frame = NinebotProtocol.parse(rxBuffer) {
            let len = Int(rxBuffer[2])
            let total = 2 + 1 + len + 2
            rxBuffer.removeFirst(min(total, rxBuffer.count))
            apply(frame)
        }
        // Guard against runaway buffer if we never see a valid header.
        if rxBuffer.count > 512 { rxBuffer.removeAll() }
    }

    private func apply(_ frame: NinebotProtocol.Frame) {
        let p = frame.payload
        switch frame.register {
        case NinebotRegisters.serialNumber:
            state.serialNumber = String(bytes: p.prefix(14), encoding: .ascii)?
                .trimmingCharacters(in: .whitespacesAndNewlines.union(.controlCharacters))
        case NinebotRegisters.firmwareVersion:
            if let v = p.leUInt16 {
                state.firmwareVersion = String(format: "%d.%d.%d",
                                               (v >> 8) & 0xF, (v >> 4) & 0xF, v & 0xF)
            }
        case NinebotRegisters.batteryPercent:
            if let v = p.leUInt16 { state.batteryPercent = Int(v) }
        case NinebotRegisters.batteryVoltage:
            if let v = p.leUInt16 { state.batteryVoltage = Double(v) / 100.0 }
        case NinebotRegisters.speed:
            if let v = p.leInt16 { state.speed = abs(Double(v) / 1000.0) }
        case NinebotRegisters.totalMileage:
            if let v = p.leUInt32 { state.totalDistance = Double(v) / 1000.0 }
        case NinebotRegisters.controllerTemp:
            if let v = p.leInt16 { state.controllerTemperature = Int(Double(v) / 10.0) }
        case NinebotRegisters.region:
            if let b = p.first { state.region = ScooterRegion(rawValue: b) }
        case NinebotRegisters.speedLimit:
            if let v = p.leUInt16 { state.speedLimit = Int(v) }
        default:
            break
        }
    }

    private func addLog(_ line: String) {
        let stamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        log.insert("[\(stamp)] \(line)", at: 0)
        if log.count > 100 { log.removeLast() }
    }

    /// Heuristic to detect a scooter from its advertised name.
    private func looksLikeScooter(_ name: String) -> Bool {
        let n = name.lowercased()
        return n.contains("ninebot") || n.contains("mi") || n.contains("scooter")
            || n.contains("misc") || n.contains("m365") || n.hasPrefix("nb")
            || n.contains("es") || n.contains("max")
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn: connectionState = .idle
        case .poweredOff: connectionState = .poweredOff
        default: connectionState = .idle
        }
    }

    func centralManager(_ central: CBCentralManager,
                       didDiscover peripheral: CBPeripheral,
                       advertisementData: [String: Any],
                       rssi RSSI: NSNumber) {
        let advName = (advertisementData[CBAdvertisementDataLocalNameKey] as? String)
            ?? peripheral.name ?? ""
        guard !advName.isEmpty, looksLikeScooter(advName) else { return }

        let scooter = DiscoveredScooter(id: peripheral.identifier,
                                       name: advName,
                                       rssi: RSSI.intValue,
                                       peripheral: peripheral)
        if let idx = discovered.firstIndex(where: { $0.id == scooter.id }) {
            discovered[idx] = scooter
        } else {
            discovered.append(scooter)
            addLog("Trouvé: \(advName) (\(RSSI) dBm)")
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        addLog("Connecté, découverte des services…")
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager,
                       didFailToConnect peripheral: CBPeripheral,
                       error: Error?) {
        connectionState = .failed(error?.localizedDescription ?? "Échec de connexion")
    }

    func centralManager(_ central: CBCentralManager,
                       didDisconnectPeripheral peripheral: CBPeripheral,
                       error: Error?) {
        pollTimer?.invalidate()
        connectionState = .idle
        state = ScooterState()
        addLog("Déconnecté.")
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == serviceUUID {
            peripheral.discoverCharacteristics([rxUUID, txUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                   didDiscoverCharacteristicsFor service: CBService,
                   error: Error?) {
        guard let chars = service.characteristics else { return }
        for ch in chars {
            if ch.uuid == rxUUID { writeChar = ch }
            if ch.uuid == txUUID { peripheral.setNotifyValue(true, for: ch) }
        }
        if writeChar != nil {
            connectionState = .connected
            addLog("Prêt.")
            startPolling()
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                   didUpdateValueFor characteristic: CBCharacteristic,
                   error: Error?) {
        guard characteristic.uuid == txUUID, let data = characteristic.value else { return }
        do {
            let clear = try crypto.decrypt([UInt8](data))
            handle(clear)
        } catch {
            // Encrypted family without an implemented scheme — surface once.
            handle([UInt8](data))
        }
    }
}
