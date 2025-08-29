//
//  VDRStartFillingRoleItem.swift
//  Documents
//
//  Created by Pavel Chernyshev on 23.04.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - Under construction. Docspace 3.2 or later

struct VDRStartFillingRoleItem: Identifiable {
    let id = UUID()
    let number: Int
    let title: String
    let color: Color
    let rawColor: String
    var appliedUser: ASCUser?
}

extension VDRStartFillingRoleItem: Equatable {
    static func == (lhs: VDRStartFillingRoleItem, rhs: VDRStartFillingRoleItem) -> Bool {
        lhs.id == rhs.id
    }
}
