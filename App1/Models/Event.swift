//
//  Event.swift
//  App1
//
//  Created by John Grese on 8/1/19.
//  Copyright © 2019 Sara Cassidy. All rights reserved.
//

import Foundation
import UserNotifications

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
    let timestamp: Int
    let event_type: Int
}
struct EventDataJSONBTResponse: Codable {
    let event: EventDataJSONBT?
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
    var isCleared = false
    var isNotified = false

    init(eventId: String, deviceId: String, timestamp: String, eventType: EventType) {
        self.eventId = eventId
        self.deviceId = deviceId
        self.timestamp = timestamp
        self.eventType = eventType
    }

    func clear() {
        isCleared = true
    }

    func notify() {
        guard let device = AppState.shared.getDeviceById(deviceId) else { return }
        let content = UNMutableNotificationContent()

        content.title = "Diaper Detective"
        content.subtitle = "\(device.name) needs your attention"
        content.body = "\(device.name)'s diaper triggered an alert at \(timestamp)."
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval:10, repeats: false)
        let request = UNNotificationRequest(identifier: "dd_event_notif=\(eventId)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if error != nil {
                print("notification error \(String(describing: error))")
            } else {
                self.isNotified = true
            }
        }
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
