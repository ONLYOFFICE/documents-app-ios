//
//  SharingInfoViewModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 19.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

struct RoomSharingFlowModel {
    var links: [SharingInfoLinkResponseModel] = []
    var sharings: [RoomUsersResponseModel] = []
}

@MainActor
final class SharingInfoViewModel: ObservableObject {
    // MARK: - Published vars

    private(set) var flowModel = RoomSharingFlowModel()
    let entityType: SharingInfoEntityType

    var canAddOneMoreLink: Bool {
        sharedLinksModels.count < linksLimit && isSharingPossible
    }
    
    var isAddingLinksAvailable: Bool {
        viewModelService.isAddingLinksAvailable
    }
    
    let linksLimit = 6
    var isPossibleCreateNewLink: Bool { viewModelService.isPossibleCreateNewLink }
    var isSharingPossible: Bool { viewModelService.isSharingPossible }
    var isUserSelectionAllow: Bool { viewModelService.isUserSelectionAllow }
    private(set) var sharingLink: URL?

    @Published var isInitializing: Bool = false
    @Published var isActivitiIndicatorDisplaying = false
    @Published var resultModalModel: ResultViewModel?
    @Published var errorMessage: String?
    @Published var admins: [ASCUserRowModel] = []
    @Published var users: [ASCUserRowModel] = []
    @Published var guests: [ASCUserRowModel] = []
    @Published var invites: [ASCUserRowModel] = []
    @Published var sharedLinksModels: [RoomSharingLinkRowModel] = [RoomSharingLinkRowModel]()

    // MARK: Navigation published vars

    @Published var selectedUser: ASCUser?
    @Published var selectdLink: SharingInfoLinkModel?
    @Published var isCreatingLinkScreenDisplaing: Bool = false
    @Published var isSharingScreenPresenting: Bool = false
    @Published var isAddUsersScreenDisplaying: Bool = false
    @Published var isDeleteAlertDisplaying: Bool = false
    @Published var isRevokeAlertDisplaying: Bool = false

    // MARK: var input

    lazy var changedLink = CurrentValueSubject<SharingInfoLinkModel?, Never>(nil)
    lazy var changedLinkBinding = Binding<SharingInfoLinkModel?>(
        get: { self.changedLink.value },
        set: { self.changedLink.send($0) }
    )

    // MARK: - Private vars

    private let viewModelService: SharingInfoViewModelService
    private let linkAccessService: SharingInfoLinkAccessService
    private var applyingDeletingLink: SharingInfoLinkModel?
    private var cancelable = Set<AnyCancellable>()

    // MARK: - Init

    init(
        entityType: SharingInfoEntityType,
        viewModelService: SharingInfoViewModelService,
        linkAccessService: SharingInfoLinkAccessService
    ) {
        self.entityType = entityType
        self.viewModelService = viewModelService
        self.linkAccessService = linkAccessService
        
        Task {
            await loadData()
        }

        changedLink
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] inputLink in
                self?.handleInputLink(inputLink)
            })
            .store(in: &cancelable)
    }

    func loadData() async {
        isInitializing = true
        do {
            let (links, sharings) = try await linkAccessService.fetchLinksAndUsers()
            flowModel.links = links
            flowModel.sharings = sharings
            buildViewModel()
        } catch {
            log.error(error)
        }
        isInitializing = false
    }

    // MARK: Handlers

    func shareButtonAction() {}

    func addUsers() {
        isAddUsersScreenDisplaying = true
    }

    func createAddLinkAction() {
        isCreatingLinkScreenDisplaing = true
    }

    func createAndCopyGeneralLink() async {
        isActivitiIndicatorDisplaying = true
        do {
            let link = try await linkAccessService.createGeneralLink()
            flowModel.links.append(link)
            UIPasteboard.general.string = link.linkInfo.shareLink
            resultModalModel = .init(result: .success, message: .linkCopiedSuccessfull)
            buildViewModel()
        } catch {
            errorMessage = error.localizedDescription
        }
        isActivitiIndicatorDisplaying = false
    }

    func createAndCopyAdditionalLink() async {
        isActivitiIndicatorDisplaying = true
        do {
            let link = try await linkAccessService.createLink(
                title: String(format: NSLocalizedString("Link name %@", comment: ""), "(1)"),
                linkType: ASCShareLinkType.external
            )
            flowModel.links.append(link)
            UIPasteboard.general.string = link.linkInfo.shareLink
            resultModalModel = .init(result: .success, message: .linkCopiedSuccessfull)
            buildViewModel()
        } catch {
            errorMessage = error.localizedDescription
        }
        isActivitiIndicatorDisplaying = false
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
        let indices = indexSet.sorted(by: >)

        for index in indices {
            guard
                let id = sharedLinksModels[safe: index]?.id,
                let deletingLink = flowModel.links.first(where: { $0.linkInfo.id == id })
            else { continue }

            // General link
            if deletingLink.isGeneral {
                buildViewModel()
                applyingDeletingLink = deletingLink
                if viewModelService.canRemoveGeneralLink {
                    isRevokeAlertDisplaying = true
                } else {
                    isDeleteAlertDisplaying = true
                }
                withAnimation { buildViewModel() }
                return
            }

            // romove from UI
            let removedModel = sharedLinksModels[safe: index]
            _ = withAnimation {
                sharedLinksModels.remove(at: index)
            }

            // Network async
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await linkAccessService.removeLink(
                        id: deletingLink.linkInfo.id,
                        title: deletingLink.linkInfo.title,
                        linkType: deletingLink.linkInfo.linkType,
                        password: deletingLink.linkInfo.password
                    )
                    await MainActor.run {
                        self.flowModel.links.removeAll { $0.linkInfo.id == deletingLink.linkInfo.id }
                    }
                } catch {
                    // discard UI when error
                    await MainActor.run {
                        if let vm = removedModel {
                            self.sharedLinksModels.insert(vm, at: index)
                        }
                        self.buildViewModel()
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    func proceedDeletingLink() async {
        guard let deletingLink = applyingDeletingLink else { return }
        do {
            if deletingLink.isGeneral {
                try await linkAccessService.removeLink(
                    id: deletingLink.linkInfo.id,
                    title: deletingLink.linkInfo.title,
                    linkType: deletingLink.linkInfo.linkType,
                    password: deletingLink.linkInfo.password
                )
                flowModel.links.removeAll(where: { $0.linkInfo.id == deletingLink.linkInfo.id })
                if viewModelService.canRemoveGeneralLink {
                    buildViewModel()
                } else {
                    isActivitiIndicatorDisplaying = true
                    await loadData()
                    resultModalModel = .init(
                        result: .success,
                        message: NSLocalizedString("The new shared link was created", comment: "")
                    )
                    isActivitiIndicatorDisplaying = false
                }
            } else {
                try await linkAccessService.removeLink(
                    id: deletingLink.linkInfo.id,
                    title: deletingLink.linkInfo.title,
                    linkType: deletingLink.linkInfo.linkType,
                    password: deletingLink.linkInfo.password
                )
                flowModel.links.removeAll(where: { $0.linkInfo.id == deletingLink.linkInfo.id })
            }
        } catch {
            self.sharedLinksModels.append(mapToLinkViewModel(link: deletingLink))
            buildViewModel()
            self.errorMessage = error.localizedDescription
        }
    }

    func declineRemoveLink() {
        applyingDeletingLink = nil
        buildViewModel()
    }
}

// MARK: Private

private extension SharingInfoViewModel {
    func handleInputLink(_ inputLink: SharingInfoLinkModel?) {
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
        users = flowModel.sharings
            .filter { !$0.user.isAdmin && !$0.user.isVisitor }
            .map { self.mapToUserViewModel(sharing: $0) }
        guests = flowModel.sharings
            .filter { $0.user.isGuest }
            .map { self.mapToUserViewModel(sharing: $0) }
        invites = flowModel.sharings
            .filter { $0.user.isUnaplyed && $0.user.isVisitor }
            .map { self.mapToUserViewModel(sharing: $0, isInvitation: true) }
    }

    func mapToUserViewModel(sharing: RoomUsersResponseModel, isInvitation: Bool = false) -> ASCUserRowModel {
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

    func mapToLinkViewModel(link: SharingInfoLinkModel) -> RoomSharingLinkRowModel {
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
            isEditAccessPossible: link.canEditAccess,
            accessRight: link.access,
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
            }
        )
    }

    private func onCopyLinkAndNotify(link: SharingInfoLinkModel?) {
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

extension SharingInfoViewModel {
    
    var title: String {
        viewModelService.title
    }
    
    var entityDescription: String? {
        viewModelService.entityDescription
    }
}

private extension String {
    static let linkCopiedSuccessfull = NSLocalizedString("Link successfully\ncopied to clipboard", comment: "")
    static let linkAndPasswordCopiedSuccessfull = NSLocalizedString("Link and password\nsuccessfully copied\nto clipboard", comment: "")
}
