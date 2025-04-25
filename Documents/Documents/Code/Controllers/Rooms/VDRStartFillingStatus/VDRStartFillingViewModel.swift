//
//  VDRFillingViewModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 23.04.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI

final class VDRStartFillingViewModel: ObservableObject {
    
    typealias RoleItem = VDRStartFillingRoleItem
    
    // TODO: - request server

    @Published var roles: [RoleItem] = [
        RoleItem(number: 1, title: "Employee", color: .yellow.opacity(0.3)),
        RoleItem(number: 2, title: "Accountant", color: .green.opacity(0.3)),
        RoleItem(number: 3, title: "Director", color: .purple.opacity(0.3)),
    ]

    func closeTapped() {
        print("Close tapped")
    }

    func startTapped() {
        print("Start tapped")
    }

    func roleTapped(_ role: RoleItem) {
        print("Tapped on role: \(role.title)")
    }
}
