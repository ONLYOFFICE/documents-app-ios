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

struct RoomSharingFlowModel {
    var links: [RoomLinkResponceModel] = []
    var sharings: [RoomUsersResponceModel] = []
}

final class RoomSharingViewModel: ObservableObject {
    // MARK: - Published vars

    private(set) var flowModel = RoomSharingFlowModel()
    let room: ASCRoom
    var isPossibleCreateNewLink: Bool {
        room.roomType != .colobaration
    }

    var canAddLink: Bool {
        sharedLinksModels.count < linksLimit && isSharingPossible
    }

    let linksLimit = 6
    var isSharingPossible: Bool { room.rootFolderType != .onlyofficeRoomArchived && room.security.editAccess }
    var isUserSelectionAllow: Bool { room.rootFolderType != .onlyofficeRoomArchived && room.security.editAccess }
    private(set) var sharingLink: URL?

    @Published var isInitializing: Bool = false
    @Published var isActivitiIndicatorDisplaying = false
    @Published var resultModalModel: ResultViewModel?
    @Published var errorMessage: String?
    @Published var admins: [ASCUserRowModel] = []
    @Published var users: [ASCUserRowModel] = []
    @Published var invites: [ASCUserRowModel] = []
    @Published var sharedLinksModels: [RoomSharingLinkRowModel] = [RoomSharingLinkRowModel]()

    // MARK: Navigation published vars

    @Published var selectedUser: ASCUser?
    @Published var selectdLink: RoomSharingLinkModel?
    @Published var isCreatingLinkScreenDisplaing: Bool = false
    @Published var isSharingScreenPresenting: Bool = false
    @Published var isAddUsersScreenDisplaying: Bool = false
    @Published var isDeleteAlertDisplaying: Bool = false
    @Published var isRevokeAlertDisplaying: Bool = false

    // MARK: var input

    lazy var changedLink = CurrentValueSubject<RoomSharingLinkModel?, Never>(nil)
    lazy var changedLinkBinding = Binding<RoomSharingLinkModel?>(
        get: { self.changedLink.value },
        set: { self.changedLink.send($0) }
    )

    // MARK: - Private vars

    private lazy var sharingRoomNetworkService = ServicesProvider.shared.roomSharingNetworkService
    private lazy var linkAccessService = ServicesProvider.shared.roomSharingLinkAccesskService
    private var applyingDeletingLink: RoomLinkResponceModel?
    private var cancelable = Set<AnyCancellable>()

    // MARK: - Init

    init(room: ASCRoom) {
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

    func loadData(completion: (() -> Void)? = nil) {
        sharingRoomNetworkService.fetch(room: room) { [weak self] links, sharings in
            guard let self else { return }
            flowModel.links = links
            flowModel.sharings = sharings
            buildViewModel()
            isInitializing = false
            completion?()
        }
    }

    // MARK: Handlers

    func shareButtonAction() {}

    func addUsers() {
        isAddUsersScreenDisplaying = true
    }

    func createAddLinkAction() {
        isCreatingLinkScreenDisplaing = true
    }

    func createAndCopyGeneralLink() {
        isActivitiIndicatorDisplaying = true
        linkAccessService.createGeneralLink(room: room) { [weak self] result in
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

    func createAndCopyAdditionalLink() {
        isActivitiIndicatorDisplaying = true
        linkAccessService.createLink(
            title: String(format: NSLocalizedString("Link name %@", comment: ""), "(1)"),
            linkType: ASCShareLinkType.external,
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

    func onAppear() {
        buildViewModel()
    }

    func onUserRemove(userId: String) {
        flowModel.sharings.removeAll(where: { $0.user.userId == userId })
        selectedUser = nil
        buildViewModel()
    }

    func deleteSharedLink(indexSet: IndexSet) {
        for index in indexSet {
            if let deletingLink = flowModel.links.first(where: { $0.linkInfo.id == sharedLinksModels[safe: index]?.id }) {
                guard !deletingLink.isGeneral else {
                    buildViewModel()
                    applyingDeletingLink = deletingLink
                    if room.roomType == .public {
                        isRevokeAlertDisplaying = true
                    } else {
                        isDeleteAlertDisplaying = true
                    }
                    withAnimation {
                        buildViewModel()
                    }
                    return
                }

                linkAccessService.removeLink(
                    id: deletingLink.linkInfo.id,
                    title: deletingLink.linkInfo.title,
                    linkType: deletingLink.linkInfo.linkType,
                    password: deletingLink.linkInfo.password,
                    room: room
                ) { [weak self] error in
                    guard let self else { return }
                    if let error {
                        self.sharedLinksModels.append(mapToLinkViewModel(link: deletingLink))
                        buildViewModel()
                        self.errorMessage = error.localizedDescription
                    } else {
                        flowModel.links.removeAll(where: { $0.linkInfo.id == deletingLink.linkInfo.id })
                    }
                }
            }
        }
        withAnimation {
            sharedLinksModels.remove(atOffsets: indexSet)
        }
    }

    func proceedDeletingLink() {
        guard let deletingLink = applyingDeletingLink else { return }
        if deletingLink.isGeneral {
            linkAccessService.removeLink(
                id: deletingLink.linkInfo.id,
                title: deletingLink.linkInfo.title,
                linkType: deletingLink.linkInfo.linkType,
                password: deletingLink.linkInfo.password,
                room: room
            ) { [weak self] error in
                guard let self else { return }
                if let error {
                    self.sharedLinksModels.append(mapToLinkViewModel(link: deletingLink))
                    buildViewModel()
                    self.errorMessage = error.localizedDescription
                } else {
                    flowModel.links.removeAll(where: { $0.linkInfo.id == deletingLink.linkInfo.id })
                    if room.roomType == .public {
                        isActivitiIndicatorDisplaying = true
                        loadData { [weak self] in
                            self?.resultModalModel = .init(
                                result: .success,
                                message: NSLocalizedString("The new shared link was created", comment: "")
                            )
                            self?.isActivitiIndicatorDisplaying = false
                        }
                    } else {
                        buildViewModel()
                    }
                }
            }
        } else {
            linkAccessService.removeLink(
                id: deletingLink.linkInfo.id,
                title: deletingLink.linkInfo.title,
                linkType: deletingLink.linkInfo.linkType,
                password: deletingLink.linkInfo.password,
                room: room
            ) { [weak self] error in
                guard let self else { return }
                if let error {
                    self.sharedLinksModels.append(mapToLinkViewModel(link: deletingLink))
                    buildViewModel()
                    self.errorMessage = error.localizedDescription
                } else {
                    flowModel.links.removeAll(where: { $0.linkInfo.id == deletingLink.linkInfo.id })
                }
            }
        }
    }

    func declineRemoveLink() {
        applyingDeletingLink = nil
        buildViewModel()
    }
}

// MARK: Private

private extension RoomSharingViewModel {
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
        // editing screen dismissed
        if selectdLink == nil, !isCreatingLinkScreenDisplaing {
            buildViewModel()
        }
        changedLink.send(nil)
    }

    func buildViewModel() {
        sharedLinksModels = flowModel.links.map { self.mapToLinkViewModel(link: $0) }
        admins = flowModel.sharings.filter { $0.user.isAdmin }.map { self.mapToUserViewModel(sharing: $0) }
        users = flowModel.sharings.filter { !$0.user.isAdmin && !$0.user.isUnaplyed }.map { self.mapToUserViewModel(sharing: $0) }
        invites = flowModel.sharings.filter { $0.user.isUnaplyed }.map { self.mapToUserViewModel(sharing: $0, isInvitation: true) }
    }

    func mapToUserViewModel(sharing: RoomUsersResponceModel, isInvitation: Bool = false) -> ASCUserRowModel {
        let onTapAction: (() -> Void)? = isUserSelectionAllow && !sharing.user.isOwner
            ? { [weak self] in self?.selectedUser = sharing.user }
            : nil
        return ASCUserRowModel(
            image: isInvitation ? .asset(Asset.Images.at) : .url(sharing.user.avatar ?? ""),
            userName: sharing.user.displayName ?? "",
            accessString: sharing.user.accessValue.title(),
            emailString: sharing.user.email ?? "",
            isOwner: sharing.user.isOwner,
            onTapAction: onTapAction
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
            id: link.linkInfo.id,
            titleString: link.linkInfo.title,
            imagesNames: imagesNames,
            isExpired: link.linkInfo.isExpired,
            isGeneral: link.isGeneral,
            isSharingPossible: isSharingPossible,
            onTapAction: { [weak self] in
                guard let self else { return }
                if isSharingPossible {
                    selectdLink = link
                }
            },
            onShareAction: { [weak self] in
                guard let self, isSharingPossible else { return }
                isSharingScreenPresenting = true
                sharingLink = URL(string: link.linkInfo.shareLink)
            },
            onCopyAction: { [weak self] in
                guard let self else { return }
                onCopyLinkAndNotify(link: link)
            }
        )
    }

    private func onCopyLinkAndNotify(link: RoomSharingLinkModel?) {
        guard let link = link else { return }
        isActivitiIndicatorDisplaying = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [self] in
            if link.linkInfo.password == nil {
                UIPasteboard.general.string = link.linkInfo.shareLink
                resultModalModel = .init(
                    result: .success,
                    message: .linkCopiedSuccessfull
                )
            } else {
                UIPasteboard.general.string = """
                \(link.linkInfo.shareLink)
                \(link.linkInfo.password ?? "")
                """
                resultModalModel = .init(
                    result: .success,
                    message: .linkAndPasswordCopiedSuccessfull
                )
            }
            isActivitiIndicatorDisplaying = false
        }
    }
}

private extension String {
    static let linkCopiedSuccessfull = NSLocalizedString("Link successfully\ncopied to clipboard", comment: "")
    static let linkAndPasswordCopiedSuccessfull = NSLocalizedString("Link and password\nsuccessfully copied\nto clipboard", comment: "")
    static let fillingFormRoomDescription = NSLocalizedString("This room is available to anyone with the link.\n External users will have Form Filler permission\n for all the files.", comment: "")
    static let publicRoomDescription = NSLocalizedString("This room is available to anyone with the link.\n External users will have View Only permission\n for all the files.", comment: "")
    static let customRoomDescription = NSLocalizedString("This room is available to anyone with the link.\n External users will have View Only permission\n for all the files.", comment: "")
}

extension RoomSharingViewModel {
    var roomTypeDescription: String {
        switch room.roomType {
        case .fillingForm:
            return .fillingFormRoomDescription
        case .public:
            return .publicRoomDescription
        case .custom:
            return .customRoomDescription
        default:
            return ""
        }
    }
}
