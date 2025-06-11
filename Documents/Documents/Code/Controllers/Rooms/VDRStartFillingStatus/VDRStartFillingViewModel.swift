//
//  VDRStartFillingViewModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 23.04.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI

// MARK: - Under construction. Docspace 3.2 or later

@MainActor
final class VDRStartFillingViewModel: ObservableObject {
    typealias RoleItem = VDRStartFillingRoleItem

    @Published private(set) var state: ScreenState = .initial

    func closeTapped() {
        print("Close tapped")
    }

    func startTapped() {
        print("Start tapped, roles:", state.roles)
    }

    func roleTapped(_ role: RoleItem) {
        print("Role tapped (add user?) for role:", role.title)
    }

    func deleteRole(_ role: RoleItem) {
        state.roles.removeAll { $0 == role }
    }

    func addRole() {
        // state.roles.append(new)
    }
}

// MARK: - ScreeenState

extension VDRStartFillingViewModel {
    struct ScreenState {
        var roles: [RoleItem] = []

        static let initial: ScreenState = {
            var s = ScreenState()
            s.roles = [
                RoleItem(number: 1, title: NSLocalizedString("Employee", comment: ""), color: .yellow.opacity(0.3)),
                RoleItem(number: 2, title: NSLocalizedString("Accountant", comment: ""), color: .green.opacity(0.3)),
                RoleItem(number: 3, title: NSLocalizedString("Director", comment: ""), color: .purple.opacity(0.3)),
            ]
            return s
        }()

        var isStartEnabled: Bool {
            !roles.isEmpty
        }
    }
}
