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
    let roles: [[String: Any]]

    init(roles: [[String: Any]]) {
        self.roles = roles
    }

    @Published private(set) var state: ScreenState = .initial

    func onAppear() {
        setupRolesToState()
    }

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

// MARK: - Private

extension VDRStartFillingViewModel {
    func setupRolesToState() {
        guard state.roles.isEmpty else { return }
        state.roles = roles.enumerated().compactMap { index, roleDict in
            guard let name = roleDict["name"] as? String,
                  let colorHex = roleDict["color"] as? String
            else { return nil }
            return RoleItem(
                number: index + 1,
                title: name,
                color: Color(UIColor(hex: colorHex)).opacity(0.3)
            )
        }
    }
}

// MARK: - ScreeenState

extension VDRStartFillingViewModel {
    struct ScreenState {
        var roles: [RoleItem] = []
        var areRolesFilled: Bool = false

        static let initial: ScreenState = ScreenState()

        var isStartEnabled: Bool {
            areRolesFilled
        }
    }
}
