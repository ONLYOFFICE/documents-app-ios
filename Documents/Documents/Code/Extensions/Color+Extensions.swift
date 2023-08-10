//
//  Color+Extensions.swift
//  Documents
//
//  Created by Alexander Yuzhin on 09.08.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 08) & 0xFF) / 255,
            blue: Double((hex >> 00) & 0xFF) / 255,
            opacity: alpha
        )
    }
}
