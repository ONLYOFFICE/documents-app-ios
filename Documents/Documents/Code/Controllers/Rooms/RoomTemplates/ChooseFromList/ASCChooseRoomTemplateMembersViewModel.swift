//
//  ASCChooseRoomTemplateMembersViewModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 08.06.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation

@MainActor
final class ASCChooseRoomTemplateMembersViewModel: ObservableObject {
    @Published var dataModel = DataModel.empty

    let onAdd: (SelectedMembers) -> Void

    init(
        ignoreMembersIds: Set<String> = [],
        onAdd: @escaping (SelectedMembers) -> Void
    ) {
        self.onAdd = onAdd
        dataModel.ignoreMembersIds = ignoreMembersIds
    }

    var screenModel: ScreenModel {
        mapToScreenModel()
    }
}

// MARK: Public

extension ASCChooseRoomTemplateMembersViewModel {
    func onAppear() {
        Task {
            async let usersTask = fetchUsers()
            async let groupsTask = fetchGroups()

            let (users, groups) = await(usersTask, groupsTask)
            dataModel.users = users
            dataModel.groups = groups
        }
    }

    func addSelectedMembers() {
        guard !dataModel.selectedIds.isEmpty else {
            onAdd(.empty)
            return
        }
        let users = dataModel.users.filter {
            guard let id = $0.userId else { return false }
            return dataModel.selectedIds.contains(id)
        }
        let groups = dataModel.groups.filter {
            guard let id = $0.id else { return false }
            return dataModel.selectedIds.contains(id)
        }
        onAdd(SelectedMembers(users: users, groups: groups))
    }
}

// MARK: Private

private extension ASCChooseRoomTemplateMembersViewModel {
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
        guard let id else { return }
        if dataModel.selectedIds.contains(id) {
            dataModel.selectedIds.remove(id)
        } else {
            dataModel.selectedIds.insert(id)
        }
    }
}

// MARK: - Mapper

private extension ASCChooseRoomTemplateMembersViewModel {
    func mapToScreenModel() -> ScreenModel {
        let cells: [Cell] = {
            let hasSearchText = !dataModel.searchText.isEmpty
            return switch dataModel.selectedSegment {
            case .users:
                dataModel.users
                    .filter {
                        guard !dataModel.ignoreMembersIds.contains($0.userId ?? "") else { return false }
                        guard hasSearchText else { return true }
                        return "\($0.displayName ?? "")\($0.email ?? "")".lowercased()
                            .contains(dataModel.searchText.trimmed.lowercased())
                    }
                    .map { user in
                        Cell.user(user.mapToRowModel(
                            isSelected: dataModel.selectedIds.contains(user.userId ?? "")
                        ) { [weak self] in
                            self?.didTapMember(id: user.userId)
                        })
                    }
            case .groups:
                dataModel.groups
                    .filter {
                        guard !dataModel.ignoreMembersIds.contains($0.id ?? "") else { return false }
                        guard hasSearchText else { return true }
                        return ($0.name ?? "").lowercased()
                            .contains(dataModel.searchText.trimmed.lowercased())
                    }
                    .map { group in
                        Cell.group(group.mapToGroupRowModel(
                            isSelected: dataModel.selectedIds.contains(group.id ?? "")
                        ) { [weak self] in
                            self?.didTapMember(id: group.id)
                        })
                    }
            }
        }()
        return ScreenModel(
            isAddButtonEnabled: !dataModel.selectedIds.isEmpty,
            rows: cells
        )
    }
}

// MARK: - Structs

extension ASCChooseRoomTemplateMembersViewModel {
    struct DataModel {
        var searchText: String = ""
        var selectedSegment: Segment = .users

        var ignoreMembersIds: Set<String> = []
        var selectedIds: Set<String> = []

        var users: [ASCUser] = []
        var groups: [ASCGroup] = []

        static let empty = DataModel()
    }

    enum Segment: String, CaseIterable, Identifiable {
        case users = "Members"
        case groups = "Groups"

        var id: String { rawValue }
    }

    struct ScreenModel {
        var isAddButtonEnabled: Bool = false
        var rows: [Cell]
    }

    enum Cell: Identifiable {
        var id: String {
            switch self {
            case let .group(model):
                model.id
            case let .user(model):
                model.id
            }
        }

        case user(ASCRoomTemplateUserMemberRowModel)
        case group(ASCRoomTemplateGroupMemberRowModel)
    }

    struct SelectedMembers {
        let users: [ASCUser]
        let groups: [ASCGroup]

        static let empty = SelectedMembers(users: [], groups: [])
    }
}

// MARK: - Extensions

private extension ASCUser {
    func mapToRowModel(isSelected: Bool, onTapAction: @escaping () -> Void) -> ASCRoomTemplateUserMemberRowModel {
        ASCRoomTemplateUserMemberRowModel(
            id: userId ?? "",
            image: .url(avatar ?? ""),
            userName: displayName ?? "",
            accessString: accessValue.title(),
            emailString: email ?? "",
            isOwner: isOwner,
            isSelected: isSelected,
            onTapAction: onTapAction
        )
    }
}

private extension ASCGroup {
    func mapToGroupRowModel(isSelected: Bool, onTapAction: @escaping () -> Void) -> ASCRoomTemplateGroupMemberRowModel {
        ASCRoomTemplateGroupMemberRowModel(
            id: id ?? "",
            name: name ?? "",
            isSelected: isSelected,
            onTapAction: onTapAction
        )
    }
}
