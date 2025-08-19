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

    // MARK: Published

    @Published var state: ScreenState = .initial

    // MARK: Props

    private(set) var dataModel: DataModel

    init(room: ASCRoom, roles: [[String: Any]]) {
        dataModel = DataModel(
            room: room,
            rawRoles: roles
        )
    }

    func onAppear() {
        setupRolesToState()
    }

    func startTapped() {
        // TODO: Check and fill form
    }

    func roleTapped(_ role: RoleItem) {
        // TODO: lastTappedRoleIndex
        state.isChooseFromListScreenDisplaying = true
    }

    func deleteRole(_ role: RoleItem) {
        state.roles.removeAll { $0 == role }
        // TODO: Map user on roles, remove only set user
    }

    func addRole() {
        state.isChooseFromListScreenDisplaying = true
    }
}

// MARK: - Private

extension VDRStartFillingViewModel {
    func setupRolesToState() {
        guard state.roles.isEmpty else { return }
        state.roles = dataModel.rawRoles.enumerated().compactMap { index, roleDict in
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

    func makeFormRolesMappingRequestModel() -> FormRolesMappingUsersRequestModel? {
        guard let formId = Int(dataModel.form.id),
              let roomId = Int(dataModel.room.id)
        else {
            return nil
        }
        return FormRolesMappingUsersRequestModel(
            formId: formId,
            roles: state.roles.compactMap {
                guard let user = $0.appliedUser else { return nil }
                return FormRolesMappingUsersRequestModel.Role(
                    userId: user.userId ?? "",
                    roleName: $0.title,
                    roleColor: $0.rawColor,
                    roomId: roomId
                )
            }
        )
    }
}

// MARK: - ScreenState

extension VDRStartFillingViewModel {
    struct DataModel {
        let room: ASCRoom
        var rawRoles: [[String: Any]] = []
        var lastTappedRoleIndex = 0
    }

    struct ScreenState {
        fileprivate(set) var roles: [RoleItem] = []
        private(set) var areRolesFilled = false
        private(set) var isStartEnabled = false

        var isChooseFromListScreenDisplaying = false

        static let initial: ScreenState = ScreenState()
    }
}
