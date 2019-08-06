//
//  SensorData.swift
//  App1
//
//  Created by John Grese on 8/1/19.
//  Copyright © 2019 Sara Cassidy. All rights reserved.
//

import Foundation

// JSON format for API
struct SensorDataJSONAPI: Codable {
    let dataId: String
    let deviceId: String
    let timestamp: String
    let temperature: Float
    let humidity: Float
}
// JSON format for bluetooth
struct SensorDataJSONBT: Codable {
    var data_id: String
    var timestamp: String
    var humidity: Float
    var temperature: Float
}
struct SensorDataJSONBTResponse: Codable {
    var data: SensorDataJSONBT
    var remaining: Int
}

// Class for SensorData objects
class SensorData {
    let dataId: String
    let deviceId: String
    let timestamp: String
    let humidity: Float
    let temperature: Float

    init(dataId: String, deviceId: String, timestamp: String, humidity: Float, temperature: Float) {
        self.dataId = dataId
        self.deviceId = deviceId
        self.timestamp = timestamp
        self.humidity = humidity
        self.temperature = temperature
    }
}
