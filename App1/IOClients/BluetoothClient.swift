import Foundation
import CoreBluetooth

let deviceNamePrefix = "dd-device-"
let eventNotificationPrefix = "new_event="
// Device Services:
let btSetupServiceId = CBUUID(string: "5b2d96cb-6532-494c-a693-49249249a4d2")
let btPairServiceId = CBUUID(string: "0c060381-c0e0-4078-bcde-6fb7dbed763b")
let btUnpairServiceId = CBUUID(string: "d66b351a-0d06-4341-a050-a854aa552a95")
let btDataServiceId = CBUUID(string: "9dce6733-198c-46e3-b138-9cce67b3d96c")
let btEventServiceId = CBUUID(string: "48241209-0402-41c0-a070-389cce673399")
let btEventNotifyServiceId = CBUUID(string: "77e90f18-69ae-4283-bf53-f940e4588afa")
let btEventClearedServiceId = CBUUID(string: "8b30ec19-6368-4920-939b-80c8cd24b3b0")
let supportedServices = [
    btSetupServiceId,
    btPairServiceId,
    btUnpairServiceId,
    btDataServiceId,
    btEventServiceId,
    btEventNotifyServiceId
]
// Device Characteristics:
let btSetupCharacteristicId = CBUUID(string: "2e97cbe5-f2f9-4c3e-9f0f-0783c1603018")
let btPairCharacteristicId = CBUUID(string: "369bcde6-73b9-4cae-97eb-753a9dcee773")
let btUnpairCharacteristicId = CBUUID(string: "b95caed7-eb75-4a9d-8e67-b359acd6eb75")
let btDataCharacteristicId = CBUUID(string: "cae57239-9c4e-4793-89e4-72b9dc6e379b")
let btEventCharacteristicId = CBUUID(string: "6db65bad-d66b-45da-adf6-7bbd5eaf57ab")
let btEventNotifyCharacteristicId = CBUUID(string: "a647940e-ebc1-4bd4-b273-a600929476cd")
let btEventClearedCharacteristicId = CBUUID(string: "ee7a4fc7-6305-48e1-92e9-7c1c9be13b63")
let supportedCharacteristics = [
    btSetupCharacteristicId,
    btPairCharacteristicId,
    btUnpairCharacteristicId,
    btDataCharacteristicId,
    btEventCharacteristicId,
    btEventNotifyCharacteristicId,
    btEventClearedCharacteristicId
]

extension Notification.Name {
    static var didSyncSensorData: Notification.Name {
        return .init(rawValue: "BluetoothClient.didSyncSensorData")
    }
    static var didReceiveEvents: Notification.Name {
        return .init(rawValue: "BluetoothClient.didSyncEvents")
    }
    static var deviceConnectionStatusChanged: Notification.Name {
        return .init(rawValue: "BluetoothClient.deviceConnectionStatusChanged")
    }
}

class BluetoothClient: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    // Singleton instance of BluetoothClient
    static let shared = BluetoothClient()

    var centralManager: CBCentralManager?
    var btDevices: Dictionary<String, BluetoothDevice> = [:]
    var btPairedPeripheralIDs: Set<String> = [Globals.demoDeviceId]

    private let notificationCenter: NotificationCenter = .default

    // private because there can be only ONE! ;)
    private override init() {
        super.init()
        centralManager = CBCentralManager(
            delegate: self,
            queue: DispatchQueue(label: "com.dd-app.centralQueue", attributes: .concurrent)
        )
    }

    func setDeviceTimestamp(peripheralUUID: String) {
        if let device = getDeviceByUUID(peripheralUUID: peripheralUUID),
           let service = device.findServiceByUUID(serviceUUID: btSetupServiceId.uuidString),
           let characteristic = device.findCharacteristicByUUID(service: service, characteristicUUID: btSetupCharacteristicId.uuidString),
           let peripheral = device.peripheral {
            let data:Data = "setup_time=\(Utils.getTimestampComponentString())".data(using: .utf8) ?? Data()
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
    }

    func clearEvent(peripheralUUID: String, eventId: String) -> Bool {
        if let device: BluetoothDevice = getDeviceByUUID(peripheralUUID: peripheralUUID),
           let service = device.findServiceByUUID(serviceUUID: btEventServiceId.uuidString),
           let characteristic = device.findCharacteristicByUUID(service: service, characteristicUUID: btEventClearedCharacteristicId.uuidString),
           let peripheral = device.peripheral {

            let data:Data = "event_cleared=\(eventId)".data(using: .utf8) ?? Data()
            peripheral.writeValue(data, for: characteristic, type: .withResponse)

            return true

        }
        return false
    }
    
    func isDeviceConnected(peripheralUUID: String) -> Bool {
        if let device: BluetoothDevice = getDeviceByUUID(peripheralUUID: peripheralUUID) {
            return device.isReady
        }
        return false
    }

    func startScanning() {
        guard let centralManager = centralManager else { return }

        if !centralManager.isScanning, centralManager.state == .poweredOn {
            print("Scanning for peripherals")
            centralManager.scanForPeripherals(withServices: nil)
        }
    }

    func stopScanning() {
        guard let centralManager = centralManager else { return }

        if centralManager.isScanning {
            print("Stopping scan for peripherals")
            centralManager.stopScan()
        }
    }

    func pairDevice(peripheralUUID: String, appID: String) {
        print("Pairing device with UUID")
        self.btPairedPeripheralIDs.insert(peripheralUUID)
    }

    func syncDeviceData(peripheralUUID: String) {
        if let device = getDeviceByUUID(peripheralUUID: peripheralUUID) {
            device.syncData()
        }
    }

    func checkDeviceEvents(peripheralUUID: String) {
        if let device = getDeviceByUUID(peripheralUUID: peripheralUUID) {
            device.syncEvents()
        }
    }

    func getDeviceByUUID(peripheralUUID: String) -> BluetoothDevice? {
        return self.btDevices.first(where: { $0.key == peripheralUUID })?.value
    }

    func parseDataResponse(data: Data) -> SensorDataJSONBTResponse? {
        var result: SensorDataJSONBTResponse? = nil
        do {
            result = try JSONDecoder().decode(SensorDataJSONBTResponse.self, from: data)
        } catch let err {
            print("Error parsing sensor data response", err)
        }
        return result
    }

    func parseEventResponse(data: Data) -> EventDataJSONBTResponse? {
        var result: EventDataJSONBTResponse? = nil
        do {
            result = try JSONDecoder().decode(EventDataJSONBTResponse.self, from: data)
        } catch let err {
            print("Error parsing event data response", err)
        }
        return result
    }

    // MARK: CBCentralManagerDelegate

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Ignore any peripherals that don't have our deviceNamePrefix
        guard let pName = peripheral.name, pName.starts(with: deviceNamePrefix) else { return }

        let pUUID = peripheral.identifier.uuidString

        if btDevices[pUUID] == nil {
            btDevices[pUUID] = BluetoothDevice(peripheral)
        }


        // If the device is currently disconnected, and already paired, connect it.
        if peripheral.state == .disconnected &&
            btPairedPeripheralIDs.contains(pUUID) {
            centralManager?.connect(peripheral)
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Connection manager's state updated
        switch central.state {
        case .resetting:
            print("Bluetooth status is RESETTING")
        case .unsupported:
            print("Bluetooth status is UNSUPPORTED")
        case .unauthorized:
            print("Bluetooth status is UNAUTHORIZED")
        case .poweredOff:
            print("Bluetooth status is POWERED OFF")
            BluetoothClient.shared.stopScanning()
        case .poweredOn:
            print("Bluetooth status is POWERED ON")
            BluetoothClient.shared.startScanning()
        case .unknown:
            print("Bluetooth status is UNKNOWN")
        @unknown default:
            print("Bluetooth status is UNKNOWN (default)")
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Peripheral Connected
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            print("Did disconnect peripheral error: \(error)")
        }
        // Peripheral Disconnected
        let pUUID = peripheral.identifier.uuidString

        if btDevices[pUUID] != nil {
            btDevices.removeValue(forKey: pUUID)
            print("Peripheral disconnected.", pUUID)
            notificationCenter.post(name: .deviceConnectionStatusChanged, object: nil, userInfo: ["deviceId": pUUID])
            startScanning()
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            print("Peripheral connection failed error: \(error)")
        }
        // Peripheral connection failed.
        print("Peripheral connection failed: ", peripheral.name ?? "", peripheral.identifier.uuidString)
    }

    // MARK: CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Did discover services error: \(error)")
            return
        }

        let pUUID = peripheral.identifier.uuidString
        let device: BluetoothDevice? = btDevices.first(where: { $0.key == pUUID })?.value

        for service in peripheral.services! {
            if let device = device {
                device.setStatusForService(uuid: service.uuid.uuidString, status: .ready)
            }
            print("Service is ready: ", service.uuid.uuidString)
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Did discover characteristic error: \(error)")
            return
        }

        guard let characteristics = service.characteristics else { return }
        let pUUID = peripheral.identifier.uuidString
        let device: BluetoothDevice? = btDevices.first(where: { $0.key == pUUID })?.value

        for characteristic in characteristics {
            if let device = device {
                device.setStatusForCharacteristic(uuid: characteristic.uuid.uuidString, status: .ready)
            }
            print("Characteristic is ready: ", characteristic.uuid.uuidString)

            // Listen for notifications from event service
            if characteristic.uuid.uuidString == btEventNotifyCharacteristicId.uuidString {
                peripheral.setNotifyValue(true, for: characteristic)
            }

            // Setup the device's timestamp:
            if characteristic.uuid.uuidString == btSetupCharacteristicId.uuidString {
                setDeviceTimestamp(peripheralUUID: pUUID)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Did update value error: \(error)")
            return
        }

        if characteristic.uuid.uuidString == btEventNotifyCharacteristicId.uuidString, let value = characteristic.value {
            // Event notification received.
            guard let strValue = String(data: value, encoding: String.Encoding.utf8) else { return }

            if strValue.starts(with: eventNotificationPrefix) {
                print("Received event notification: ", strValue)
                checkDeviceEvents(peripheralUUID: peripheral.identifier.uuidString)
            }
        } else if characteristic.uuid.uuidString == btEventCharacteristicId.uuidString, let value = characteristic.value {
            // Value updated for event characteristic...
            let data = String(data: value, encoding: String.Encoding.utf8)!
            print("Event received from device \(peripheral.identifier.uuidString): ", data)

            if let result = parseEventResponse(data: value), let device = getDeviceByUUID(peripheralUUID: peripheral.identifier.uuidString) {

                if let e = result.event {
                    let eventDate = Date(timeIntervalSince1970: TimeInterval(e.timestamp))
                    let timestamp = Utils.ISO8601StringFromDate(date: eventDate)
                    let event = Event(eventId: e.event_id, deviceId: device.deviceId, timestamp: timestamp, eventType: EventType(rawValue: e.event_type)!)
                    device.syncEventsItems.append(event)
                }

                if result.remaining > 0 {
                    print("Reading next event...")
                    peripheral.readValue(for: characteristic)
                } else {
                    // Pass sensor data to delegate.
                    notificationCenter.post(name: .didReceiveEvents, object: nil, userInfo: ["deviceId": device.deviceId, "events": device.syncEventsItems])
                    // Reset the device's sync state
                    device.syncEventsInProgress = false
                    device.syncEventsItems = []
                }
            }
        } else if characteristic.uuid.uuidString == btDataCharacteristicId.uuidString, let value = characteristic.value {
            // Value updated for data characteristic.
            let data = String(data: value, encoding: String.Encoding.utf8)!
            print("Data received from device \(peripheral.identifier.uuidString): ", data)

            if let result = parseDataResponse(data: value), let device = getDeviceByUUID(peripheralUUID: peripheral.identifier.uuidString) {

                let sensorData = SensorData(dataId: result.data.data_id, deviceId: device.deviceId, timestamp: result.data.timestamp, humidity: result.data.humidity, temperature: result.data.temperature)

                device.syncDataItems.append(sensorData)
                if result.remaining > 0 {
                    print("Reading next block of sync data...")
                    peripheral.readValue(for: characteristic)
                } else {
                    print("Sync complete.")
                    // Pass sensor data to delegate.
                    notificationCenter.post(name: .didSyncSensorData, object: nil, userInfo: ["deviceId": device.deviceId, "data": device.syncDataItems])
                    // Reset the device's sync state
                    device.syncDataInProgress = false
                    device.syncDataItems = []
                }
            }
        }
    }
}

enum ServiceStatus {
    case ready
    case notReady
}

enum CharacteristicStatus {
    case ready
    case notReady
}

class BluetoothDevice {
    var peripheral: CBPeripheral?
    var syncDataInProgress: Bool = false
    var syncDataItems: Array<SensorData> = []
    var syncEventsInProgress: Bool = false
    var syncEventsItems: Array<Event> = []
    var deviceId: String {
        return peripheral!.identifier.uuidString
    }

    var isReady: Bool {
        let servicesReady = serviceStatuses.reduce(into: true) { result, item in
            result = result && item.value == .ready
        }
        let characteristicsReady = characteristicStatuses.reduce(into: true) { result, item in
            result = result && item.value == .ready
        }
        return servicesReady && characteristicsReady
    }
    private var serviceStatuses: Dictionary<String, ServiceStatus> = [
        btPairServiceId.uuidString: .notReady,
        btUnpairServiceId.uuidString: .notReady,
        btDataServiceId.uuidString: .notReady,
        btEventServiceId.uuidString: .notReady
    ]
    private var characteristicStatuses: Dictionary<String, CharacteristicStatus> = [
        btPairCharacteristicId.uuidString: .notReady,
        btUnpairCharacteristicId.uuidString: .notReady,
        btDataCharacteristicId.uuidString: .notReady,
        btEventCharacteristicId.uuidString: .notReady
    ]

    init(_ peripheral: CBPeripheral) {
        self.peripheral = peripheral
    }

    func setStatusForService(uuid: String, status: ServiceStatus) {
        serviceStatuses[uuid] = status
    }

    func setStatusForCharacteristic(uuid: String, status: CharacteristicStatus) {
        characteristicStatuses[uuid] = status
    }

    func findServiceByUUID(serviceUUID: String) -> CBService? {
        return peripheral?.services?.first(where: { $0.uuid.uuidString ==  serviceUUID})
    }

    func findCharacteristicByUUID(service: CBService, characteristicUUID: String) -> CBCharacteristic? {
        return service.characteristics?.first(where: { $0.uuid.uuidString == characteristicUUID })
    }

    func syncData() {
        if !isReady || syncDataInProgress {
            return
        }

        guard let service = findServiceByUUID(serviceUUID: btDataServiceId.uuidString), let characteristic = findCharacteristicByUUID(service: service, characteristicUUID: btDataCharacteristicId.uuidString) else { return }

        // Start reading data (device responds with one data point at a time)...
        syncDataInProgress = true
        peripheral?.readValue(for: characteristic)
    }

    func syncEvents() {
        if !isReady || syncEventsInProgress {
            return
        }

        guard let service = findServiceByUUID(serviceUUID: btEventServiceId.uuidString), let characteristic = findCharacteristicByUUID(service: service, characteristicUUID: btEventCharacteristicId.uuidString) else { return }

        // Start reading events (device responds with one event at a time)...
        syncEventsInProgress = true
        peripheral?.readValue(for: characteristic)
    }
}
