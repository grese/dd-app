//
//  APIClient.swift
//  App1
//
//  Created by John Grese on 7/31/19.
//  Copyright © 2019 Sara Cassidy. All rights reserved.
//

import Foundation

enum HTTPMethods: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

class APIClient {
    // Shared singleton instance of APIClient
    static var shared = APIClient()

    private let baseURL = "https://iotstripes-ddapi.azurewebsites.net/api"
    private var sensorDataURL: String {
        return "\(baseURL)/SensorData"
    }
    private var deviceEventURL: String {
        return "\(baseURL)/DeviceEvents"
    }

    func fetchEvents(userID: String, deviceID: String, completion: ((_ events: Array<Event>, _ success: Bool) -> Void)?) {
        self.request(url: deviceEventURL, method: HTTPMethods.get, data: nil) {result, success in
            print("Events fetched: ", result ?? "")
            if let completion = completion, let result = result as? Array<Event> {
                completion(result, false)
            }
        }
    }

    func saveEvents(events: Array<Event>, deviceID: String, completion: ((_ success: Bool) -> Void)?) {
        guard let device = AppState.shared.getDeviceById(deviceID) else { return }
        // Generate concurrent API calls for all events.
        let dispatchGroup = DispatchGroup()
        var statuses: Array<Bool> = []

        for event in events {
            // Start async block.
            dispatchGroup.enter()
            // format JSON body for event request
            let eventObj = EventDataJSONAPI(deviceId: device.dbId, deviceGuid: device.deviceId, eventId: event.eventId, timestamp: event.timestamp, eventType: event.eventType.rawValue)
            let eventJSON:Data? = try? JSONEncoder().encode(eventObj)

            // Create POST request to save event
            self.request(url: deviceEventURL, method: HTTPMethods.post, data: eventJSON) {response, success in
                if !success {
                    print("Error saving event: ", response ?? "")
                } else {
                    event.isSaved = true
                }
                DispatchQueue.main.async {
                    // Resolve async request & save status
                    statuses.append(success)
                    // Resolve async block.
                    dispatchGroup.leave()
                }
            }
        }
        // Fire requests in parallel:
        dispatchGroup.notify(queue: .main) {
            let allSuccessful = statuses.reduce(true, {a, b in a && b})
            if let completion = completion {
                completion(allSuccessful)
            }
        }
    }

    func saveSensorData(sensorDataItems: Array<SensorData>, deviceID: String, completion: ((_ success: Bool) -> Void)?) {
        // Generate concurrent API calls for all sensor data..
        let dispatchGroup = DispatchGroup()
        var statuses: Array<Bool> = []

        for data in sensorDataItems {
            // Start async block.
            dispatchGroup.enter()
            // Format JSON body for sensordata request
            let sensorData = SensorDataJSONAPI(dataId: data.dataId, deviceId: deviceID, timestamp: data.timestamp, temperature: data.temperature, humidity: data.humidity)
            let jsonData:Data? = try? JSONEncoder().encode(sensorData)

            // Create POST request to save sensor data.
            self.request(url: sensorDataURL, method: HTTPMethods.post, data: jsonData) {response, success in
                if !success {
                    print("Error saving sensor data: ", response ?? "")
                }
                // Resolve async request and save status.
                DispatchQueue.main.async {
                    statuses.append(success)
                    // Resolve async block.
                    dispatchGroup.leave()
                }
            }
        }
        // Fire requests in parallel:
        dispatchGroup.notify(queue: .main) {
            let allSuccessful = statuses.reduce(true, {a, b in a && b})
            if let completion = completion {
                print("Sensor data saved.")
                completion(allSuccessful)
            }
        }
    }

    private func request(url: String, method: HTTPMethods, data: Data?, completion: ((_ result: Any?, _ success: Bool) -> Void)?) {
        guard let url = URL(string: url) else { return }
        var request = URLRequest(url: url)

        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let data = data {
            request.httpBody = data
        }

        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            guard error == nil else {
                print("Request error: ", error?.localizedDescription ?? "")
                if let completion = completion {
                    completion(nil, false)
                }
                return
            }
            guard let data = data else {
                print("No data in response: ", error?.localizedDescription ?? "")
                if let completion = completion {
                    completion(nil, true)
                }
                return
            }
            do {
                //create json object from data
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    print("Response: ", json)
                    
                    if let completion = completion {
                        completion(json, true)
                    }
                }
            } catch let error {
                print(error.localizedDescription)
                if let completion = completion {
                    completion(nil, false)
                }
            }
        })
        task.resume()
    }

    // Enforce singleton pattern with private init. - There can be only ONE! ;)
    private init() {}
}
