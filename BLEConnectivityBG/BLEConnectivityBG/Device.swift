//
//  Device.swift
//  BLEConnectivityBG
//
//  Created by Prajwal Lobo on 04/07/17.
//  Copyright © 2017 Prajwal Lobo. All rights reserved.
//

import Foundation


/*B_NAME : Name of the bluettooth peripheral your looking for, can be obtained once the device is discoverd after scanning
 peripheralDevice : This is the device identifier obtained from the didDiscoverDelegate
 */


struct Device{
    static let peripheralDevice = "00001760-CAFE-FACE-1700-556F41535653"
    static let peipheralChar = "00001760-CAFE-FACE-1700-556F41535653"
    static let B_NAME = "DFF4-D60E"
}
