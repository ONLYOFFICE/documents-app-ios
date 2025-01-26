//
//  UserListViewModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 16.05.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

final class UserListViewModel: ObservableObject {
    typealias User = UserList.User

    @Published var searchText: String = ""
    @Published var users: [User] = []
    @Published var isLoading: Bool = false
    @Binding var selectedUser: ASCUser?

    private let userListNetworkService: UserListNetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private(set) var allUsers: [ASCUser] = []
    private var ignoreUserId: String?

    init(
        userListNetworkService: UserListNetworkServiceProtocol = UserListNetworkService(),
        selectedUser: Binding<ASCUser?>,
        ignoreUserId: String?
    ) {
        self.userListNetworkService = userListNetworkService
        self.ignoreUserId = ignoreUserId
        _selectedUser = selectedUser
        setupBindings()
    }

    private func setupBindings() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                self?.fetchUsers(filterValue: searchText)
            }
            .store(in: &cancellables)
    }

    private func fetchUsers(filterValue: String? = nil) {
        guard !isLoading else { return }
        isLoading = true
        userListNetworkService.fetchUsers(filterValue: filterValue) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case let .success(ascUsers):
                    self.allUsers = ascUsers
                    self.users = self.filterUsers(ascUsers: ascUsers)
                case let .failure(error):
                    log.error("Error fetching users: \(error)")
                }
            }
        }
    }

    private func filterUsers(ascUsers: [ASCUser]) -> [User] {
        return ascUsers
            .filter {
                let isAdmin = $0.userType == .roomAdmin || $0.userType == .docspaseAdmin
                return isAdmin
                guard let ignoreUserId = ignoreUserId else { return isAdmin }
                return $0.userId != ignoreUserId && isAdmin
            }
            .map(mapToUserListUser)
    }

    private func mapToUserListUser(ascUser: ASCUser) -> User {
        User(
            id: ascUser.userId ?? "",
            name: ascUser.displayName ?? "",
            role: ascUser.userType.description,
            email: ascUser.email ?? "",
            imageName: ascUser.avatar ?? ""
        )
    }
}
