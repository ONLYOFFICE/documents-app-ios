//
//  VDRFillingViewModel.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 23.04.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI

final class VDRFillingViewModel: ObservableObject {
    
    // TODO: - request server
    
    @Published var roles: [VDRFillingRoleItem] = [
        VDRFillingRoleItem(number: 1, title: "Employee", color: .yellow.opacity(0.3)),
        VDRFillingRoleItem(number: 2, title: "Accountant", color: .green.opacity(0.3)),
        VDRFillingRoleItem(number: 3, title: "Director", color: .purple.opacity(0.3))
    ]

    func closeTapped() {
        print("Close tapped")
    }

    func startTapped() {
        print("Start tapped")
    }

    func roleTapped(_ role: VDRFillingRoleItem) {
        print("Tapped on role: \(role.title)")
    }
}
