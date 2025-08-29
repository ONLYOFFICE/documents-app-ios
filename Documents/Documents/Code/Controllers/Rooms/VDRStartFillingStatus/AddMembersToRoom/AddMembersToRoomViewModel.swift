//
//  AddMembersToRoomViewModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 22/08/25.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation

@MainActor
final class AddMembersToRoomViewModel: ObservableObject {
    // MARK: Published

    @Published var dataModel = DataModel.empty

    @Published private(set) var screenModel: ScreenModel = .empty
    @Published private(set) var availableAccess: [ASCShareAccess] = ASCDocSpaceAccessDocumentFormProvider().get()

    // MARK: Props

    let room: ASCRoom

    // MARK: - Private

    private var bag = Set<AnyCancellable>()

    let onAdd: ([ASCUser]) -> Void

    init(
        room: ASCRoom,
        hiddenUsers: [ASCUser],
        onAdd: @escaping ([ASCUser]) -> Void
    ) {
        self.room = room
        self.onAdd = onAdd
        dataModel.hiddenUsers = Set(hiddenUsers.compactMap { $0.userId })
        $dataModel
            .map { [weak self] dm in
                self?.mapToScreenModel(dataModel: dm) ?? .empty
            }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] sm in
                self?.screenModel = sm
            }
            .store(in: &bag)
    }
}

// MARK: Public

extension AddMembersToRoomViewModel {
    func onAppear() {
        Task {
            async let usersTask = fetchUsers()
            async let guestsTask = fetchGuests()

            let (users, guests) = await(usersTask, guestsTask)
            dataModel.users = users.filter { !dataModel.hiddenUsers.contains($0.userId ?? "") }
            dataModel.guests = guests.filter { !dataModel.hiddenUsers.contains($0.userId ?? "") }
        }
    }

    func setAccess(_ access: ASCShareAccess) {
        dataModel.selectedAccess = access
    }

    func didTapAddToRoom() {
        let members: [ASCUser] = (dataModel.users + dataModel.guests)
            .compactMap {
                guard let id = $0.userId, dataModel.selectedUsers.contains(id) else { return nil }
                return $0
            }
        guard !members.isEmpty else { return }
        onAdd(members)
    }

    func addSelectedToRoom(dismiss: @escaping () -> Void) {
        Task {
            guard !dataModel.selectedUsers.isEmpty else { return }
            dataModel.isLoading = true
            do {
                let selectedUsers = (dataModel.users + dataModel.guests)
                    .filter {
                        guard let id = $0.userId else { return false }
                        return dataModel.selectedUsers.contains(id)
                    }

                let inviteRequestModel = OnlyofficeInviteRequestModel()
                inviteRequestModel.invitations = selectedUsers
                    .compactMap {
                        guard let id = $0.userId else { return nil }
                        return OnlyofficeInviteItemRequestModel(id: id, access: dataModel.selectedAccess)
                    }

                if let result = try await OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Sharing.inviteRequestBase(folder: room), inviteRequestModel.toJSON()),
                   let statusCode = result.statusCode,
                   (200 ..< 400).contains(statusCode)
                {
                    onAdd(selectedUsers)
                    dismiss()
                }
            } catch {
                log.error(error)
            }

            dataModel.isLoading = false
        }
    }
}

// MARK: Private

private extension AddMembersToRoomViewModel {
    func fetchUsers() async -> [ASCUser] {
        do {
            return try await OnlyofficeApiClient.request(
                OnlyofficeAPI.Endpoints.People.room(roomId: room.id),
                PeopleRoomRequestModel(includeShared: nil).dictionary
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
                PeopleGuestsRequestModel().dictionary
            )?.result ?? []
        } catch {
            log.error(error)
            return []
        }
    }

    func didTapMember(user: ASCUser) {
        guard let userId = user.userId else { return }
        if dataModel.selectedUsers.contains(userId) {
            dataModel.selectedUsers.remove(userId)
        } else {
            dataModel.selectedUsers.insert(userId)
        }
    }
}

// MARK: - Mapper

private extension AddMembersToRoomViewModel {
    func mapToScreenModel(dataModel: DataModel) -> ScreenModel {
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
                        Cell.user(user.mapToRowModel(isSelected: dataModel.selectedUsers.contains(user.userId ?? "")) { [weak self] in
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
                        Cell.user(user.mapToRowModel(isSelected: dataModel.selectedUsers.contains(user.userId ?? "")) { [weak self] in
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

extension AddMembersToRoomViewModel {
    struct DataModel {
        var searchText: String = ""
        var selectedSegment: Segment = .users
        var isLoading: Bool = false

        fileprivate(set) var users: [ASCUser] = []
        fileprivate(set) var guests: [ASCUser] = []

        fileprivate(set) var hiddenUsers: Set<String> = []
        var selectedUsers: Set<String> = []

        var selectedAccess: ASCShareAccess = .fillForms

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

    struct ScreenModel: Equatable {
        var rows: [Cell]

        static let empty = ScreenModel(rows: [])
    }

    enum Cell: Identifiable, Equatable {
        var id: String {
            switch self {
            case let .guest(model), let .user(model):
                model.id
            }
        }

        case user(ASCRoomTemplateUserMemberRowModel)
        case guest(ASCRoomTemplateUserMemberRowModel)

        static func == (lhs: Cell, rhs: Cell) -> Bool {
            switch (lhs, rhs) {
            case let (.user(l), .user(r)):
                return l == r
            case let (.guest(l), .guest(r)):
                return l == r
            default:
                return false
            }
        }
    }
}

// MARK: - Extensions

private extension ASCUser {
    func mapToRowModel(isSelected: Bool, onTapAction: @escaping () -> Void) -> ASCRoomTemplateUserMemberRowModel {
        ASCRoomTemplateUserMemberRowModel(
            id: userId ?? "",
            image: .url(avatar ?? ""),
            userName: displayName ?? "",
            accessString: userType.description,
            emailString: email ?? "",
            isOwner: isOwner,
            isSelected: isSelected,
            displayCircleMark: true,
            onTapAction: onTapAction
        )
    }
}

enum AddMembersToRoomRowModel {
    case user(ASCRoomTemplateUserMemberRowModel)
    case guest(ASCRoomTemplateUserMemberRowModel)
}
