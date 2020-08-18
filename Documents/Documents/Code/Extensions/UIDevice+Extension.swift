//
//  UIDevice+Extension.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/13/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit

enum ScreenInches: CGFloat {
    case inches35 = 480 // iPhone 4s
    case inches4  = 568 // iPhone SE
    case inches47 = 667 // iPhone 7
    case inches55 = 736 // iPhone 7 Plus
}

extension UIDevice {
    static var phone: Bool {
        return self.current.userInterfaceIdiom == .phone
    }
    
    static var pad: Bool {
        return self.current.userInterfaceIdiom == .pad
    }
    
    static var height: CGFloat {
        return max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
    }
    
    static func greatOfInches(_ inches: ScreenInches) -> Bool {
        return UIDevice.height >= inches.rawValue
    }
    
    static var screenPixel: CGFloat {
        return 1.0 / UIScreen.main.scale;
    }
    
    static var platform: String {
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }

    static var device: Device {
        return Device()
    }

    static var allowEditor: Bool {
        let allUnsupportedDevicesForEdit: [Device] = [
            .iPhone4, .iPhone4s, .iPad2, .iPad3
        ]
        return !device.isOneOf(allUnsupportedDevicesForEdit)
    }
}
