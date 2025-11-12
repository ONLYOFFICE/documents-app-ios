//
//  InviteUsersViewModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 18.05.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

final class InviteUsersViewModel: ObservableObject {
    // MARK: Published vars

    @Published var isExternalLinkSwitchActive: Bool = false
    @Published var selectedAccessRight: ASCShareAccess = .none
    @Published var linkStr: String = ""
    @Published var isLoading: Bool = false
    @Published var isExternalLinkSectionAvailable: Bool = false
    @Published var externalLink: ASCSharingOprionsExternalLink?

    // MARK: Navigation related published vars

    @Published var isAddUsersScreenDisplaying: Bool = false
    @Published var isInviteByEmailsScreenDisplaying: Bool = false
    @Published var isSharingScreenPresenting: Bool = false

    // MARK: Public vars

    let room: ASCRoom
    var accessMenuItems: [MenuViewItem] {
        accessProvider.get().map { access in
            MenuViewItem(text: access.title(), customImage: access.swiftUIImage) { [unowned self] in
                setAccessRight(access)
            }
        }
    }

    var dismissAction: (() -> Void)?

    private(set) var sharingLink: URL?

    // MARK: Private vars

    private var cancelable = Set<AnyCancellable>()
    private var service: InviteUsersService = InviteUsersServiceImp()
    private lazy var accessProvider: ASCSharingSettingsAccessProvider = ASCSharingSettingsExternalLinkAccessRoomsProvider(
        roomType: room.roomType ?? .viewOnly,
        rightHoldersTableType: .users
    )

    private var preventToggleAction: Bool = false

    // MARK: Init

    init(room: ASCRoom) {
        self.room = room

        $isExternalLinkSwitchActive
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] isActive in
                guard let self else { return }
                if self.preventToggleAction {
                    self.preventToggleAction = false
                    return
                }
                changeLinkAccess(newAccess: isActive ? .contentCreator : .none)
            })
            .store(in: &cancelable)
    }

    // MARK: Public methods

    func fetchData() {
        isLoading = true
        service.loadExternalLink(entity: room) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async { [self] in
                self.isLoading = false
                self.isExternalLinkSectionAvailable = true
                switch result {
                case let .success(externalLink):
                    self.externalLink = externalLink
                    if let externalLink {
                        self.linkStr = externalLink.link
                        self.selectedAccessRight = externalLink.access
                        self.preventToggleAction = true
                        self.isExternalLinkSwitchActive = ![ASCShareAccess.deny, .none].contains(where: { externalLink.access == $0 })
                    }
                case let .failure(error):
                    log.error(error.localizedDescription, error)
                }
            }
        }
    }

    func shareLink() {
        guard let externalLink else { return }
        isSharingScreenPresenting = true
        sharingLink = URL(string: externalLink.link)
    }

    // MARK: Private methods

    private func setAccessRight(_ accessRight: ASCShareAccess) {
        selectedAccessRight = accessRight
        changeLinkAccess(newAccess: accessRight)
    }

    private func changeLinkAccess(newAccess: ASCShareAccess) {
        Task { @MainActor in
            do {
                let externalLink = try await service.setExternalLinkAccess(
                    linkId: externalLink?.id,
                    room: room,
                    settingAccess: newAccess
                )
                if let externalLink {
                    self.linkStr = externalLink.link
                    self.selectedAccessRight = externalLink.access
                    self.externalLink = externalLink
                } else {
                    self.externalLink = nil
                    self.preventToggleAction = true
                    self.isExternalLinkSwitchActive = false
                }
            } catch {
                self.preventToggleAction = true
                self.isExternalLinkSwitchActive.toggle()
                log.error(error.localizedDescription, error)
            }
        }
    }
}
