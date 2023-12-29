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
    var sharings: [RoomUsersResponceModel] = []
}

final class RoomSharingViewModel: ObservableObject {
    // MARK: - Published vars

    private(set) var flowModel = RoomSharingFlowModel()
    let room: ASCFolder
    let additionalLinksLimit = 5

    @Published var isInitializing: Bool = false
    @Published var admins: [ASCUserRowModel] = []
    @Published var users: [ASCUserRowModel] = []
    @Published var invites: [ASCUserRowModel] = []
    @Published var errorMessage: String?
    @Published var generalLinkModel: RoomSharingLinkRowModel?
    @Published var additionalLinkModels: [RoomSharingLinkRowModel] = [RoomSharingLinkRowModel]()
    @Published var selctedUser: ASCUser?
    @Published var selectdLink: RoomSharingLinkModel?

    // MARK: - Private vars

    private lazy var sharingRoomNetworkService = ServicesProvider.shared.roomSharingNetworkService

    // MARK: - Init

    init(room: ASCFolder) {
        self.room = room
        isInitializing = true
        loadData()
    }

    func loadData() {
        sharingRoomNetworkService.fetch(room: room) { [weak self] links, sharings in
            guard let self else { return }
            flowModel.links = links
            flowModel.sharings = sharings
            buildViewModel()
            isInitializing = false
        }
    }

    // MARK: Handlers

    func shareButtonAction() {}

    func createAddLinkAction() {}

    func createGeneralLink() {}

    func onAppear() {
        buildViewModel()
    }

    func deleteAdditionalLink() {}

    func deleteGeneralLink() {}
}

// MARK: Private

private extension RoomSharingViewModel {
    private func buildViewModel() {
        if let generalLink = flowModel.links.first(where: { $0.isGeneral }) {
            generalLinkModel = mapToLinkViewModel(link: generalLink)
        }
        additionalLinkModels = flowModel.links.filter { !$0.isGeneral }.map { self.mapToLinkViewModel(link: $0) }
        admins = flowModel.sharings.filter { $0.user.isAdmin }.map { self.mapToUserViewModel(sharing: $0) }
        users = flowModel.sharings.filter { !$0.user.isAdmin && !$0.user.isUnaplyed }.map { self.mapToUserViewModel(sharing: $0) }
        invites = flowModel.sharings.filter { $0.user.isUnaplyed }.map { self.mapToUserViewModel(sharing: $0) }
    }

    private func mapToUserViewModel(sharing: RoomUsersResponceModel) -> ASCUserRowModel {
        ASCUserRowModel(
            image: sharing.user.avatar ?? "",
            title: sharing.user.displayName ?? "",
            subtitle: sharing.user.accessValue.title(),
            isOwner: sharing.user.isOwner,
            onTapAction: { [weak self] in
                guard !sharing.user.isOwner, let self else { return }
                selctedUser = sharing.user
            }
        )
    }

    private func mapToLinkViewModel(link: RoomLinkResponceModel) -> RoomSharingLinkRowModel {
        var imagesNames: [String] = []
        if link.linkInfo.password != nil {
            imagesNames.append("lock.circle.fill")
        }
        if link.linkInfo.expirationDate != nil {
            imagesNames.append("clock.fill")
        }
        return RoomSharingLinkRowModel(
            titleString: link.linkInfo.title,
            imagesNames: imagesNames,
            isExpired: link.linkInfo.isExpired,
            onTapAction: { [weak self] in
                self?.selectdLink = link
            },
            onShareAction: shareButtonAction
        )
    }
}
