//
//  ASCStartFillingAssignToRoleViewModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 12/08/25.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation

@MainActor
final class ASCStartFillingAssignToRoleViewModel: ObservableObject {
    // MARK: Published

    @Published var dataModel = DataModel.empty

    // MARK: Dependencies

    private lazy var sharingRoomNetworkService = ServicesProvider.shared.roomSharingNetworkService

    // MARK: Props

    let onAdd: (ASCUser) -> Void

    init(
        ignoreMembersIds: Set<String> = [],
        onAdd: @escaping (ASCUser) -> Void
    ) {
        self.onAdd = onAdd
    }

    var screenModel: ScreenModel {
        mapToScreenModel()
    }
}

// MARK: Public

extension ASCStartFillingAssignToRoleViewModel {
    func onAppear() {
        Task {
            async let usersTask = fetchUsers() // TODO: fetch room users
            async let guestsTask = fetchUsers() // TODO: fetch guests

            let (users, guests) = await(usersTask, guestsTask)
            dataModel.users = users
            dataModel.guests = guests
        }
    }
}

// MARK: Private

private extension ASCStartFillingAssignToRoleViewModel {
    func fetchUsers() async -> [ASCUser] {
        do {
            let result = try await OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.People.all)
            return result?.result?
                .filter { user in
                    (user.isAdmin || user.isRoomAdmin) && !user.isOwner
                } ?? []
        } catch {
            log.error(error)
            return []
        }
    }

    func fetchGroups() async -> [ASCGroup] {
        do {
            let result = try await OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.People.groups)
            return result?.result ?? []
        } catch {
            log.error(error)
            return []
        }
    }

    func didTapMember(id: String?) {
        // MARK: - TODO
    }
}

// MARK: - Mapper

private extension ASCStartFillingAssignToRoleViewModel {
    func mapToScreenModel() -> ScreenModel {
        let cells: [Cell] = {
            let hasSearchText = !dataModel.searchText.isEmpty
            return switch dataModel.selectedSegment {
            case .users:
                dataModel.users
                    .filter {
                        guard hasSearchText else { return true }
                        return "\($0.displayName ?? "")\($0.email ?? "")".lowercased()
                            .contains(dataModel.searchText.trimmed.lowercased())
                    }
                    .map { user in
                        Cell.user(user.mapToRowModel { [weak self] in
                            self?.didTapMember(id: user.userId)
                        })
                    }
            case .guests:
                dataModel.guests
                    .filter {
                        guard hasSearchText else { return true }
                        return "\($0.displayName ?? "")\($0.email ?? "")".lowercased()
                            .contains(dataModel.searchText.trimmed.lowercased())
                    }
                    .map { user in
                        Cell.user(user.mapToRowModel { [weak self] in
                            self?.didTapMember(id: user.userId)
                        })
                    }
            }
        }()
        return ScreenModel(
            isAddButtonEnabled: true, // TODO: Remove
            rows: cells
        )
    }
}

// MARK: - Structs

extension ASCStartFillingAssignToRoleViewModel {
    struct DataModel {
        var searchText: String = ""
        var selectedSegment: Segment = .users

        var users: [ASCUser] = []
        var guests: [ASCUser] = []

        static let empty = DataModel()
    }

    enum Segment: String, CaseIterable, Identifiable {
        case users = "Members"
        case guests = "Guests"

        var id: String { rawValue }

        var localizedString: String {
            switch self {
            case .users: NSLocalizedString("Members", comment: "")
            case .guests: NSLocalizedString("Guests", comment: "")
            }
        }
    }

    struct ScreenModel {
        var isAddButtonEnabled: Bool = false
        var rows: [Cell]
    }

    enum Cell: Identifiable {
        var id: String {
            switch self {
            case let .guest(model), let .user(model):
                model.id
            }
        }

        case user(ASCRoomTemplateUserMemberRowModel)
        case guest(ASCRoomTemplateUserMemberRowModel)
    }
}

// MARK: - Extensions

private extension ASCUser {
    func mapToRowModel(onTapAction: @escaping () -> Void) -> ASCRoomTemplateUserMemberRowModel {
        ASCRoomTemplateUserMemberRowModel(
            id: userId ?? "",
            image: .url(avatar ?? ""),
            userName: displayName ?? "",
            accessString: accessValue.title(),
            emailString: email ?? "",
            isOwner: isOwner,
            isSelected: false,
            displayCircleMark: false,
            onTapAction: onTapAction
        )
    }
}

enum ASCStartFillingAssignToRoleRowModel {
    case user(ASCRoomTemplateUserMemberRowModel)
    case guest(ASCRoomTemplateUserMemberRowModel)
}
