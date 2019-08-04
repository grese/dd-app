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
    @IBOutlet weak var bluetoothImage: UIImageView!
    @IBOutlet weak var gotItButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var statusImage: UIImageView!
    @IBOutlet weak var viewAnalyticsButton: UIButton!
    
    @IBAction func gotItButtonTapped(_ sender: UIButton!) {
        // TODO: send message over bluetooth to device to clear state.
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.device = AppState.shared.account?.devices[0]
        AppState.shared.delegate = self
    }

    func didRecordEvent(event: Event) {
        print("Event detected", event)
        // Change image.
        // Update message
        
        if event.eventType == .changed {
            // do smiley.
            statusImage.image = UIImage(named: "10020-smiling-face-icon")
        } else {
            // do frownie.
            statusImage.image = UIImage(named: "tear-emoji-by-google")
        }
        
    }
    

}

