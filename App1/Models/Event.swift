//
//  Event.swift
//  App1
//
//  Created by John Grese on 8/1/19.
//  Copyright © 2019 Sara Cassidy. All rights reserved.
//

import Foundation

// JSON format for API
struct EventDataJSONAPI: Codable {
    let deviceId: Int
    let deviceGuid: String
    let eventId: String?
    let timestamp: String
    let eventType: Int
}
// JSON format for bluetooth
struct EventDataJSONBT: Codable {
    let event_id: String
    let timestamp: String
    let event_type: Int
}
struct EventDataJSONBTResponse: Codable {
    let event: EventDataJSONBT
    let remaining: Int
}
// Event types
enum EventType: Int {
    case one = 1
    case two = 2
    case changed = 3
}

// Model for event objects
class Event {
    let eventId: String
    let deviceId: String
    let timestamp: String
    let eventType: EventType
    var isSaved = false

    init(eventId: String, deviceId: String, timestamp: String, eventType: EventType) {
        self.eventId = eventId
        self.deviceId = deviceId
        self.timestamp = timestamp
        self.eventType = eventType
    }
}

class EventChartData {
    let weekDate: Date
    let eventCount: Int
    
    init(weekDate: Date, eventCount: Int) {
        self.weekDate = weekDate
        self.eventCount = eventCount
    }
}
