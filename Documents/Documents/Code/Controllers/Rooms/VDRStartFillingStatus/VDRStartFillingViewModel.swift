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

    // MARK: Dependencies

    private var networkService = OnlyofficeApiClient.shared

    init(
        form: ASCFile,
        room: ASCRoom,
        roles: [[String: Any]]
    ) {
        dataModel = DataModel(
            form: form,
            room: room,
            rawRoles: roles
        )
    }

    func onAppear() {
        setupRolesToState()
    }

    func startTapped() {
        Task {
            guard let requestModel = makeFormRolesMappingRequestModel() else { return }
            state.isLoading = true
            do {
                let result = try await OnlyofficeApiClient.request(
                    OnlyofficeAPI.Endpoints.Files.mapFormRolesToUsers(file: dataModel.form),
                    requestModel.dictionary
                )
                if (200 ..< 300).contains(result?.statusCode ?? 0) {
                    state.finishWithSuccess = true
                }
            } catch {
                state.finishWithError = StringError(error.localizedDescription)
                log.error(error)
            }
            state.isLoading = false
        }
    }

    func roleTapped(_ role: RoleItem) {
        guard let index = state.roles.firstIndex(where: { $0.id == role.id }) else {
            return
        }
        dataModel.lastTappedRoleIndex = index
        state.isChooseFromListScreenDisplaying = true
    }

    func deleteRoleAppliedUser(_ role: RoleItem) {
        guard let index = state.roles.firstIndex(where: { $0.id == role.id }),
              state.roles[safe: index] != nil
        else {
            return
        }
        state.roles[index].appliedUser = nil
    }

    func addRoleUser(_ user: ASCUser) {
        guard state.roles[safe: dataModel.lastTappedRoleIndex] != nil else {
            return
        }
        state.roles[dataModel.lastTappedRoleIndex].appliedUser = user
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
                color: Color(UIColor(hex: colorHex)).opacity(0.3),
                rawColor: String(colorHex
                    .replacingOccurrences(of: "#", with: "")
                    .prefix(6))
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
        let form: ASCFile
        let room: ASCRoom
        var rawRoles: [[String: Any]] = []
        var lastTappedRoleIndex = 0
    }

    struct ScreenState {
        fileprivate(set) var roles: [RoleItem] = []

        var areRolesFilled: Bool {
            roles.allSatisfy { $0.appliedUser != nil && !isLoading }
        }

        var isStartEnabled: Bool { areRolesFilled }

        var isChooseFromListScreenDisplaying = false
        var isLoading = false

        var finishWithError: StringError?
        var finishWithSuccess = false

        static let initial: ScreenState = ScreenState()
    }
}
