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
    @Published var accessModels: [ASCShareAccessRowModel] = []
    @Published var isAccessChanging: Bool = false
    @Published var error: String?
    private let accesses: [ASCShareAccess] = [.roomManager, .powerUser]
    private let room: ASCFolder
    private let user: ASCUser

    let networkService: RoomUsersAccessNetworkService = RoomUsersAccessNetworkServiceImp()

    init(room: ASCFolder, user: ASCUser) {
        self.room = room
        self.user = user
        updateModels()
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
