//
//  AppState.swift
//  App1
//
//  Created by John Grese on 8/1/19.
//  Copyright © 2019 Sara Cassidy. All rights reserved.
//

import Foundation

// Defining a couple globals:
struct Globals {
    static var demoUserId = "ead003f4-83c1-483d-b40b-76574303f96e"
    static var demoDeviceId = "8B6C0307-669B-C31F-BEC1-0BF7D4D5843E"
//    static var demoDeviceId = "4AB3DAF7-78EE-6E92-6E73-A7ED1B3C4F9C"
//    static var demoDeviceId = "7B21B295-8EE5-984B-0364-01031B647628"
}

// JSON codables for the AppState (JSON file saved to filesystem)
struct EventJSON: Codable {
    var uuid: String
    var timestamp: String
    var eventType: Int
    var isSaved: Bool?
    var isCleared: Bool?
    var isNotified: Bool?
}
struct DeviceJSON: Codable {
    var id: Int
    var uuid: String
    var name: String
    var status: Int
    var events: Array<EventJSON>
}
struct UserJSON: Codable {
    var id: Int
    var uuid: String
    var name: String
    var email: String
}
struct AccountJSON: Codable {
    var user: UserJSON
    var devices: Array<DeviceJSON>
}

// AppStateDelegate protocol.
protocol AppStateDelegate: class {
    func didRecordEvents()
}

// A simple singleton object used to store the current
// state of the application.  Note that it is stored in
// a JSON file in the filesystem just for demo purposes.
// CoreData should be used in the long-run to persist data.
class AppState {
    // Create a shared sington instance.
    static var shared = AppState()
    let notificationCenter: NotificationCenter = NotificationCenter.default
    weak var delegate: AppStateDelegate?
    var account: Account?
    var accountReady: Bool {
        return account != nil
    }
    var notificationsAllowed: Bool {
        return account?.notificationsAllowed ?? false
    }

    private var fileName:String = "dd-app-state.json"
    private var writeInProgress = false
    private var readInProgress = false
    
    func clearEvent(eventId: String, deviceId: String) {
        if let device = getDeviceById(deviceId), let event = device.events.first(where: { eventId == $0.eventId }) {
            event.clear()
            save()
        }
    }

    func getActiveEvent(deviceId: String) -> Event? {
        if let device = getDeviceById(deviceId) {
            // Find first event that is not "changed" and has not yet been cleared.
            return device.events.first(where: { $0.eventType != .changed && !$0.isCleared })
        }
        return nil
    }

    func updateNotificationsAllowed(allowed: Bool) {
        if let account = account, allowed != account.notificationsAllowed {
            account.notificationsAllowed = allowed
            save()
        }
    }

    func getDeviceById(_ deviceId: String) -> Device? {
        return account?.devices.first(where: { $0.deviceId == deviceId })
    }

    func addSensorData(_ data: Array<SensorData>, deviceId: String, autoSave: Bool = true) {
        if let device = getDeviceById(deviceId) {
            device.unsavedSensorData.append(contentsOf: data)
        }
        if autoSave {
            save()
        }
    }

    func addEvents(_ events: Array<Event>, deviceId: String, autoSave: Bool = true) {
        // Add the events to the app state.
        if let device = getDeviceById(deviceId) {
            device.events.append(contentsOf: events)
            delegate?.didRecordEvents()
        }
        if autoSave {
            save()
        }
    }

    func addEvent(_ event: Event, deviceId: String, autoSave: Bool = true) {
        if let device = getDeviceById(deviceId) {
            device.events.append(event)
            delegate?.didRecordEvents()
        }
        if autoSave {
            save()
        }
    }

    func save() {
        saveState()
    }

    func restore() {
        if !stateFileExists() {
            // Generate account data for demo:
            print("Generating demo account")
            account = generateDemoAccount()
            saveState()
        } else {
            // Restore the state from JSON file:
            print("Restoring state from filesystem")
            readState()
        }
    }

    func destroy() {
        if let fileURL = getFileURL() {
            print("Deleting state file.")
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                print("Error occurred while deleting state file.")
            }
        }
    }

    private func getFileURL() -> URL? {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            // Read the JSON file, and decode the JSON...
            return dir.appendingPathComponent(fileName)
        }
        return nil
    }

    // Save state to file system.
    private func saveState() {
        if writeInProgress || readInProgress {
            print("State is already being read or updated.")
            return
        }
        writeInProgress = true

        if let account = account, let accountData = accountToJSON(account), let fileURL = getFileURL() {
            do {
                try accountData.write(to: fileURL)
            } catch {
                print("Error occurred while persisting account JSON file")
            }
        }
        writeInProgress = false
    }

    // Reads the state from filesystem.
    private func readState() {
        if writeInProgress || readInProgress {
            print("State is already being read or updated.")
            return
        }
        readInProgress = true
        // Move JSON reading and parsing to background thread.
        if let fileURL = getFileURL() {
            if let jsonData = try? Data(contentsOf: fileURL) {
                account = accountFromJSON(jsonData)
            } else {
                print("Error occurred while reading account JSON file")
            }
        }
        readInProgress = false
    }

    private func accountToJSON(_ account: Account) -> Data? {
        let user = account.user
        let jsonUser: UserJSON = UserJSON(id: user.dbId, uuid: user.userId, name: user.name, email: user.email)
        var jsonDevices: Array<DeviceJSON> = []

        for d in account.devices {
            var jsonEvents: Array<EventJSON> = []

            for e in d.events {
                jsonEvents.append(EventJSON(uuid: e.eventId, timestamp: e.timestamp, eventType: e.eventType.rawValue, isSaved: e.isSaved, isCleared: e.isCleared, isNotified: e.isNotified))
            }

            let jsonDevice: DeviceJSON = DeviceJSON(id: d.dbId, uuid: d.deviceId, name: d.name, status: d.status.rawValue, events: jsonEvents)
            jsonDevices.append(jsonDevice)
        }

        let accountJSON = AccountJSON(user: jsonUser, devices: jsonDevices)
        let encoder = JSONEncoder()
        return try? encoder.encode(accountJSON)
    }

    private func accountFromJSON(_ jsonData: Data) -> Account? {
        if let accountJSON = try? JSONDecoder().decode(AccountJSON.self, from: jsonData) {

            // Convert the codable JSON objects to real objects.
            let userJSON = accountJSON.user
            let user = User(dbId: userJSON.id, userId: userJSON.uuid, name: userJSON.name, email: userJSON.email)
            var devices: Array<Device> = []

            for dJSON in accountJSON.devices {
                var events: Array<Event> = []

                for eJSON in dJSON.events {
                    events.append(Event(eventId: eJSON.uuid, deviceId: dJSON.uuid, timestamp: eJSON.timestamp, eventType: EventType(rawValue: eJSON.eventType)!, isSaved: eJSON.isSaved, isCleared: eJSON.isCleared, isNotified: eJSON.isNotified))
                }
                devices.append(Device(dbId: dJSON.id, deviceId: dJSON.uuid, name: dJSON.name, status: DeviceStatus(rawValue: dJSON.status)!, events: events))
            }

            return Account(user: user, devices: devices)
        }

        return nil
    }

    private func stateFileExists() -> Bool {
        guard let fileURL = getFileURL() else { return false }

        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    // Generates a demo account (for iot-stripes demo)
    private func generateDemoAccount() -> Account {
        let demoUser = User(dbId: 5, userId: Globals.demoUserId, name: "Demo User", email: "iot-stripes-demo@cmu.edu")
        let demoDevice = Device(dbId: 3, deviceId: Globals.demoDeviceId, name: "El Baby", status: .connected)
        return Account(user: demoUser, devices: [demoDevice])
    }

    func addInternalNotificationObservers() {
        // Setup observers for notifications triggered by bluetooth client.
        notificationCenter.addObserver(self, selector: #selector(didReceiveEvents), name: .didReceiveEvents, object: nil)
        notificationCenter.addObserver(self, selector: #selector(didSyncSensorData), name: .didSyncSensorData, object: nil)
    }

    @objc private func didReceiveEvents(_ notification: Notification) {
        if let userInfo = notification.userInfo, let deviceId:String = userInfo["deviceId"] as? String, let events:Array<Event> = userInfo["events"] as? Array<Event> {
            for e in events {
                if e.eventType != .changed {
                    e.notify()
                }
            }
            addEvents(events, deviceId: deviceId)
            APIClient.shared.saveEvents(events: events, deviceID: deviceId, completion: nil)
        }
    }

    @objc private func didSyncSensorData(_ notification: Notification) {
        if let userInfo = notification.userInfo, let deviceId:String = userInfo["deviceId"] as? String, let data:Array<SensorData> = userInfo["data"] as? Array<SensorData> {
            addSensorData(data, deviceId: deviceId)
            // When API supports sensor data, we can save it in back-end
        }
    }

    // Private initializer to enorce singleton.
    private init() {
        addInternalNotificationObservers()
    }
}
