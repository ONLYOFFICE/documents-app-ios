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

    @Published var router = Router()
    @Published var dataModel = DataModel.empty

    // MARK: Props

    let room: ASCRoom
    let onAdd: (ASCUser) -> Void

    init(
        room: ASCRoom,
        onAdd: @escaping (ASCUser) -> Void
    ) {
        self.room = room
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
            guard !dataModel.isUsersFetched || (dataModel.users + dataModel.guests).isEmpty else { return }
            async let usersTask = fetchUsers()
            async let guestsTask = fetchGuests()

            let (users, guests) = await(usersTask, guestsTask)
            dataModel.users = users
            dataModel.guests = guests
            dataModel.isUsersFetched = true
        }
    }

    func addedToRoom(members: [ASCUser]) {
        let users = members.filter { !$0.isGuest }
        let guests = members.filter { $0.isGuest }
        dataModel = dataModel.reduce {
            $0.users.append(contentsOf: users)
            $0.guests.append(contentsOf: guests)
        }
        router.isAddToRoomDisplaying = false
    }
}

// MARK: Private

private extension ASCStartFillingAssignToRoleViewModel {
    func fetchUsers() async -> [ASCUser] {
        do {
            return try await OnlyofficeApiClient.request(
                OnlyofficeAPI.Endpoints.People.room(roomId: room.id),
                PeopleRoomRequestModel().dictionary
            )?.result ?? []
        } catch {
            log.error(error)
            return []
        }
    }

    func fetchGuests() async -> [ASCUser] {
        do {
            return try await OnlyofficeApiClient.request(
                OnlyofficeAPI.Endpoints.People.room(roomId: room.id),
                PeopleGuestsRequestModel(includeShared: true).dictionary
            )?.result ?? []
        } catch {
            log.error(error)
            return []
        }
    }

    func didTapMember(user: ASCUser) {
        onAdd(user)
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
                            self?.didTapMember(user: user)
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
                            self?.didTapMember(user: user)
                        })
                    }
            }
        }()
        return ScreenModel(
            rows: cells
        )
    }
}

// MARK: - Structs

extension ASCStartFillingAssignToRoleViewModel {
    struct DataModel {
        var isUsersFetched = false
        var searchText: String = ""
        var selectedSegment: Segment = .users

        var users: [ASCUser] = []
        var guests: [ASCUser] = []

        static let empty = DataModel()
    }

    struct Router {
        var isAddToRoomDisplaying = false
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
            accessString: userType.description,
            emailString: email ?? "",
            isOwner: isOwner,
            isSelected: false,
            displayCircleMark: false,
            onTapAction: onTapAction
        )
    }
}

extension ASCStartFillingAssignToRoleViewModel.DataModel {
    func reduce(_ transform: (inout Self) -> Void) -> Self {
        var copy = self
        transform(&copy)
        return copy
    }
}

enum ASCStartFillingAssignToRoleRowModel {
    case user(ASCRoomTemplateUserMemberRowModel)
    case guest(ASCRoomTemplateUserMemberRowModel)
}
