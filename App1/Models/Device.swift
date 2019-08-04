//
//  Device.swift
//  App1
//
//  Created by John Grese on 8/1/19.
//  Copyright © 2019 Sara Cassidy. All rights reserved.
//

import Foundation

enum DeviceStatus: Int {
    case disconnected = 0
    case connected = 1
}

class Device {
    let dbId: Int
    let deviceId: String
    let name: String
    let status: DeviceStatus
    var events: Array<Event> = []
    var unsavedSensorData: Array<SensorData> = []

    init(dbId: Int, deviceId: String, name: String, status: DeviceStatus, events: Array<Event> = []) {
        self.deviceId = deviceId
        self.dbId = dbId
        self.name = name
        self.status = status
        self.events = events
    }
}
