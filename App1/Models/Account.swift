//
//  Account.swift
//  App1
//
//  Created by John Grese on 8/1/19.
//  Copyright © 2019 Sara Cassidy. All rights reserved.
//

import Foundation

class Account {
    var user: User
    var devices: Array<Device>
    var notificationsAllowed: Bool = false

    init(user: User, devices: Array<Device>) {
        self.user = user
        self.devices = devices
    }
}

