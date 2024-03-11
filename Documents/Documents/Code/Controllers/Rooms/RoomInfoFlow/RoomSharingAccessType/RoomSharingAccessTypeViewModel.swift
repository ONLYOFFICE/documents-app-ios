//
//  RoomSharingAccessTypeViewModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 28/12/23.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation

class RoomSharingAccessTypeViewModel: ObservableObject {
    typealias UserIdentifier = String
    
    @Published var accessModels: [ASCShareAccessRowModel] = []
    @Published var isAccessChanging: Bool = false
    @Published var error: String?
    private let accesses: [ASCShareAccess] = [.roomManager, .powerUser, .editing, .fillForms, .review, .comment, .read]
    private let room: ASCFolder
    private let user: ASCUser
    private let onRemove: (UserIdentifier) -> Void

    private let networkService: RoomUsersAccessNetworkService = ServicesProvider.shared.roomUsersAccessNetworkService

    init(room: ASCFolder, user: ASCUser, onRemove: @escaping (UserIdentifier) -> Void) {
        self.room = room
        self.user = user
        self.onRemove = onRemove
        updateModels()
    }
    
    func removeUser() {
        guard let userId = user.userId else { return }
        isAccessChanging = true
        networkService.changeUserAccess(room: room, userId: userId, newAccess: .none) { [weak self] error in
            guard let self else { return }
            if error == nil {
                user.accessValue = .none
            }
            self.error = error?.localizedDescription
            self.updateModels()
            isAccessChanging = false
            self.onRemove(userId)
        }
    }

    private func updateModels() {
        accessModels = accesses.map { mappingAccess in

            ASCShareAccessRowModel(
                uiImage: mappingAccess.image(),
                name: mappingAccess.title(),
                isChecked: mappingAccess == user.accessValue
            ) { [weak self, tappedAccess = mappingAccess] in
                self?.handle(tappedAccess: tappedAccess)
            }
        }
    }

    private func handle(tappedAccess: ASCShareAccess) {
        guard let userId = user.userId, user.accessValue != tappedAccess else { return }
        isAccessChanging = true
        networkService.changeUserAccess(room: room, userId: userId, newAccess: tappedAccess) { [weak self] error in
            guard let self else { return }
            if error == nil {
                user.accessValue = tappedAccess
            }
            self.error = error?.localizedDescription
            self.updateModels()
            isAccessChanging = false
        }
    }
}
