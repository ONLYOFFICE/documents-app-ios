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

    @Published var isInitializing: Bool = false
    @Published var room: ASCFolder
    @Published var admins: [ASCUserRowModel] = []
    @Published var users: [ASCUserRowModel] = []
    @Published var invites: [ASCUserRowModel] = []
    @Published var errorMessage: String?
    @Published var generalLinkModel: RoomSharingLinkRowModel?
    @Published var additionalLinkModels: [RoomSharingLinkRowModel] = [RoomSharingLinkRowModel]()

    // MARK: - Private vars

    private lazy var sharingRoometworkService: RoomSharingNetworkServiceProtocol = RoomSharingNetworkService()

    // MARK: - Init

    init(room: ASCFolder, sharingRoomService: RoomSharingNetworkServiceProtocol) {
        self.room = room
        isInitializing = true
        loadData()
    }

    func onTap() {}

    func shareButtonAction() {}

    func createAddLinkAction() {}

    func loadData() {
        sharingRoometworkService.fetch(room: room) { [weak self] links, sharings in
            guard let self else { return }
            if let generalLink = links.first(where: { $0.isGeneral }) {
                generalLinkModel = mapToLinkViewModel(link: generalLink)
            }
            additionalLinkModels = links.filter { !$0.isGeneral }.map { self.mapToLinkViewModel(link: $0) }
            admins = sharings.filter { $0.user.isAdmin }.map { self.mapToUserViewModel(sharing: $0) }
            users = sharings.filter { !$0.user.isAdmin && !$0.user.isUnaplyed }.map { self.mapToUserViewModel(sharing: $0) }
            invites = sharings.filter { $0.user.isUnaplyed }.map { self.mapToUserViewModel(sharing: $0) }
            isInitializing = false
        }
    }

    private func mapToUserViewModel(sharing: RoomUsersResponceModel) -> ASCUserRowModel {
        ASCUserRowModel(
            image: sharing.user.avatar ?? "",
            title: sharing.user.displayName ?? "",
            subtitle: sharing.access.title(),
            isOwner: sharing.user.isOwner
        )
    }

    private func mapToLinkViewModel(link: RoomLinkResponceModel) -> RoomSharingLinkRowModel {
        var imagesNames: [String] = []
        if link.sharedTo.password != nil {
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
