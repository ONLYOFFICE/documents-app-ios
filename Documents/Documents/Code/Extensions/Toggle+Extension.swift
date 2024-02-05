//
//  Toggle+Extension.swift
//  Documents
//
//  Created by Alexander Yuzhin on 10.01.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

public extension Toggle {
    func tintColor(_ color: Color) -> some View {
        if #available(iOS 14.0, *) {
            return self.toggleStyle(SwitchToggleStyle(tint: color))
        } else {
            return self
        }
    }
}
