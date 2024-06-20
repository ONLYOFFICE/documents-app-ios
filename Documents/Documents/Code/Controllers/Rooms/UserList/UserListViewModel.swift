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
        fetchUsers()
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
        isLoading = true
        userListNetworkService.fetchUsers(filterValue: filterValue) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case let .success(ascUsers):
                    self.allUsers = ascUsers
                    self.users = ascUsers
                        .map(self.mapToUserListUser)
                        .filter {
                            guard let ignoreUserId = self.ignoreUserId else { return true }
                            return $0.id != ignoreUserId
                        }
                case let .failure(error):
                    log.error("Error fetching users: \(error)")
                }
            }
        }
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
