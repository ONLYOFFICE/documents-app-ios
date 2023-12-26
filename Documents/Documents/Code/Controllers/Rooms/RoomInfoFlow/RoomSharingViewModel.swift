//
//  RoomSharingViewModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 19.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

// needed info for presentation:
// 1. public or custom

struct RoomSharingFlowModel {
    var links: [RoomLinkResponceModel] = []
}

final class RoomSharingViewModel: ObservableObject {
    
    // MARK: - Published vars
    
    var flowModel: RoomSharingFlowModel = .init()

    @Published var room: ASCFolder
    @Published var admins: [ASCUserRowModel] = []
    @Published var users: [ASCUserRowModel] = []
    @Published var errorMessage: String?
    @Published var generalLinkModel: RoomSharingLinkRowModel = .empty
    @Published var additionalLinkModels: [RoomSharingLinkRowModel] = [RoomSharingLinkRowModel]()
    
    //MARK: - Private vars
    private lazy var sharingRoomService: NetworkSharingRoomServiceProtocol = NetworkSharingRoomService()

    // MARK: - Init
    
    init(room: ASCFolder, sharingRoomService: NetworkSharingRoomServiceProtocol) {
        self.room = room
        loadLinks()
        loadUsers()
    }

    func onTap() {
        
    }
    
    func shareButtonAction() {
        
    }
    
    func createAddLinkAction() {
        
    }
    
    func loadUsers() {
        sharingRoomService.fetchRoomUsers(room: room) { result in
            switch result {
            case let .success(users):
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    for user in users {
                        if user.sharedTo.isAdmin {
                            admins.append(mapToUserViewModel(user: user))
                        } else {
                            self.users.append(mapToUserViewModel(user: user))
                        }
                    }
                }
            case let .failure(error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func loadLinks() {
        sharingRoomService.fetchRoomLinks(room: room) { result in
            switch result {
            case let .success(links):
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    for link in links {
                        var imagesNames: [String] = []
                        if link.sharedTo.password != nil{
                            imagesNames.append("lock.circle.fill")
                        }
                        if link.sharedTo.expirationDate != nil {
                            imagesNames.append("clock.fill")
                        }
                        if link.sharedTo.primary, !link.sharedTo.title.isEmpty {
                            generalLinkModel = mapToLinkViewModel(link: link)
                        } else {
                            self.additionalLinkModels.append(mapToLinkViewModel(link: link))
                        }
                    }
                }
            case let .failure(error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func mapToUserViewModel(user: RoomUsersResponceModel) -> ASCUserRowModel {
        return ASCUserRowModel(image: user.sharedTo.avatar, title: user.sharedTo.displayName, subtitle: user.access.title(), isOwner: user.sharedTo.isOwner)
    }
    
    private func mapToLinkViewModel(link: RoomLinkResponceModel) -> RoomSharingLinkRowModel {
        var imagesNames: [String] = []
        if link.sharedTo.password != nil{
            imagesNames.append("lock.circle.fill")
        }
        if link.sharedTo.expirationDate != nil {
            imagesNames.append("clock.fill")
        }
        return RoomSharingLinkRowModel(
            titleString: link.sharedTo.title,
            imagesNames: imagesNames,
            isExpired: link.sharedTo.isExpired,
            onTapAction: onTap,
            onShareAction: shareButtonAction
        )
    }
}