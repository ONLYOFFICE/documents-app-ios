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
    @Published var isActivitiIndicatorDisplaying = false
    @Published var resultModalModel: ResultModalView.Model?
    @Published var errorMessage: String?
    @Published var admins: [ASCUserRowModel] = []
    @Published var users: [ASCUserRowModel] = []
    @Published var invites: [ASCUserRowModel] = []
    @Published var generalLinkModel: RoomSharingLinkRowModel?
    @Published var additionalLinkModels: [RoomSharingLinkRowModel] = [RoomSharingLinkRowModel]()

    // MARK: Navigation published vars

    @Published var selctedUser: ASCUser?
    @Published var selectdLink: RoomSharingLinkModel?
    @Published var isCreatingLinkScreenDisplaing: Bool = false

    // MARK: var input

    lazy var changedLink = CurrentValueSubject<RoomSharingLinkModel?, Never>(nil) // TODO: rename to inputLink
    lazy var changedLinkBinding = Binding<RoomSharingLinkModel?>(
        get: { self.changedLink.value },
        set: { self.changedLink.send($0) }
    )

    // MARK: - Private vars

    private lazy var sharingRoomNetworkService = ServicesProvider.shared.roomSharingNetworkService
    private lazy var linkAccessService = ServicesProvider.shared.roomSharingLinkAccesskService
    private var cancelable = Set<AnyCancellable>()

    // MARK: - Init

    init(room: ASCFolder) {
        self.room = room
        isInitializing = true
        loadData()

        changedLink
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] inputLink in
                self?.handleInputLink(inputLink)
            })
            .store(in: &cancelable)
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

    func createAddLinkAction() {
        isCreatingLinkScreenDisplaing = true
    }

    func createAndCopyGeneralLink() {
        createAndCopyLink(name: "Shared link")
    }

    func createAndCopyAdditionalLink() {
        createAndCopyLink(name: "Link name (1)")
    }

    func onAppear() {
        buildViewModel()
    }

    func deleteAdditionalLink() {}

    func deleteGeneralLink() {}
}

// MARK: Private

private extension RoomSharingViewModel {
    func createAndCopyLink(name: String) {
        isActivitiIndicatorDisplaying = true
        linkAccessService.createLink(
            title: name,
            linkType: 1, // TODO:
            room: room
        ) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(link):
                flowModel.links.append(link)
                UIPasteboard.general.string = link.linkInfo.shareLink
                resultModalModel = .init(result: .success, message: .linkCopiedSuccessfull)
                buildViewModel()
            case let .failure(error):
                errorMessage = error.localizedDescription
            }
            isActivitiIndicatorDisplaying = false
        }
    }

    func handleInputLink(_ inputLink: RoomSharingLinkModel?) {
        guard let inputLink else { return }
        if let index = flowModel.links.firstIndex(where: { $0.linkInfo.id == inputLink.linkInfo.id }) {
            if [.deny, .none].contains(inputLink.access) {
                flowModel.links.remove(at: index)
            } else {
                flowModel.links[index] = inputLink
            }
        } else {
            flowModel.links.append(inputLink)
        }
    }

    func buildViewModel() {
        if let generalLink = flowModel.links.first(where: { $0.isGeneral }) {
            generalLinkModel = mapToLinkViewModel(link: generalLink)
        }
        additionalLinkModels = flowModel.links.filter { !$0.isGeneral }.map { self.mapToLinkViewModel(link: $0) }
        admins = flowModel.sharings.filter { $0.user.isAdmin }.map { self.mapToUserViewModel(sharing: $0) }
        users = flowModel.sharings.filter { !$0.user.isAdmin && !$0.user.isUnaplyed }.map { self.mapToUserViewModel(sharing: $0) }
        invites = flowModel.sharings.filter { $0.user.isUnaplyed }.map { self.mapToUserViewModel(sharing: $0, isInvitation: true) }
    }

    func mapToUserViewModel(sharing: RoomUsersResponceModel, isInvitation: Bool = false) -> ASCUserRowModel {
        ASCUserRowModel(
            image: isInvitation ? .asset(Asset.Images.at) :  .url(sharing.user.avatarRetina ?? ""),
            title: sharing.user.displayName ?? "",
            subtitle: sharing.user.accessValue.title(),
            isOwner: sharing.user.isOwner,
            onTapAction: { [weak self] in
                guard !sharing.user.isOwner, let self else { return }
                selctedUser = sharing.user
            }
        )
    }

    func mapToLinkViewModel(link: RoomLinkResponceModel) -> RoomSharingLinkRowModel {
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

private extension String {
    static let linkCopiedSuccessfull = NSLocalizedString("Link successfully copied to clipboard", comment: "")
}
