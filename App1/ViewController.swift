//
//  ViewController.swift
//  App1
//
//  Created by Sara Cassidy on 7/25/19.
//  Copyright © 2019 Sara Cassidy. All rights reserved.
//

import UIKit
import Charts

class ViewController: UIViewController, AppStateDelegate {
    var device: Device?

    let happyImageName = "10020-smiling-face-icon"
    let sadImageName = "tear-emoji-by-google"
    let btConnectedImageName = "bluetooth-logo-2"
    let btDisconnectedImageName = "Gray Bluetooth"

    private let notificationCenter: NotificationCenter = .default

    @IBOutlet weak var bluetoothImage: UIImageView!
    @IBOutlet weak var gotItButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var statusImage: UIImageView!
    @IBOutlet weak var viewAnalyticsButton: UIButton!
    
    @IBAction func gotItButtonTapped(_ sender: UIButton) {
        if let deviceId = device?.deviceId, let event = AppState.shared.getActiveEvent(deviceId: deviceId) {
            BluetoothClient.shared.clearEvent(peripheralUUID: deviceId, eventId: event.eventId)
            AppState.shared.clearEvent(eventId: event.eventId, deviceId: deviceId)
            
            updateView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup observers for notifications triggered by bluetooth client.
        notificationCenter.addObserver(self, selector: #selector(bluetoothStatusDidUpdate), name: .deviceConnectionStatusChanged, object: nil)
        notificationCenter.addObserver(self, selector: #selector(onEventReceived), name: .didReceiveEvents, object: nil)
        // Just grabbing the first device (for demo)
        device = AppState.shared.getDeviceById(Globals.demoDeviceId)
        AppState.shared.delegate = self
        updateView()
    }

    override func viewWillAppear(_ animated: Bool) {
        updateView()
        super.viewWillAppear(animated)
    }

    @objc private func bluetoothStatusDidUpdate(_ notification: Notification) {
        // Notifications are fired on background thread.  Must update UI in main thread.
        DispatchQueue.main.async { [weak self] in
            self?.updateView()
        }
    }
    

    @objc private func onEventReceived(_ notification: Notification) {
        // Notifications are fired on background thread.  Must update UI in main thread.
        DispatchQueue.main.async { [weak self] in
            self?.updateView()
        }
    }

    func updateBluetoothStatus() {
        var btImageName = btDisconnectedImageName
        if let device = device, BluetoothClient.shared.isDeviceConnected(peripheralUUID: device.deviceId) {
            btImageName = btConnectedImageName
        }
        bluetoothImage.image = UIImage(named: btImageName)
    }

    func updateStatusImage(_ event: Event?) {
        var imageName = happyImageName
        if let event = event {
            imageName = event.eventType != .changed ? sadImageName : happyImageName
        }
        self.statusImage.image = UIImage(named: imageName)
    }

    func updateMessageLabel(_ event: Event?) {
        let name = device?.name ?? "Baby"
        var message = "\(name)'s diaper is all clear"
        if let event = event, event.eventType != .changed {
            message = "\(name) is waiting on you to change his diaper"
        }
        self.messageLabel.text = message
    }

    func updateButton(_ event: Event?) {
        var enabled = false
        if let event = event, event.eventType != .changed {
            enabled = true
        }
        self.gotItButton.isEnabled = enabled
    }

    func updateView() {
        if let deviceId = device?.deviceId {
            let event = AppState.shared.getActiveEvent(deviceId: deviceId)
            // Update the images, labels, and buttons.
            updateStatusImage(event)
            updateMessageLabel(event)
            updateButton(event)
            updateBluetoothStatus()
        }
    }

    func didRecordEvents() {
        updateView()
    }

    deinit {
        // If your app supports iOS 8 or earlier, you need to manually
        // remove the observer from the center. In later versions
        // this is done automatically.
        notificationCenter.removeObserver(self)
    }
}

