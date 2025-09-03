//
//  ASCTrackingWindow.swift
//  Documents-develop
//
//  Created by Victor Tihovodov on 3/9/25.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import UIKit

final class ASCTrackingWindow: UIWindow {
    static var lastActiveScene: UIWindowScene?

    override func sendEvent(_ event: UIEvent) {
        Self.lastActiveScene = windowScene
        super.sendEvent(event)
    }
}
