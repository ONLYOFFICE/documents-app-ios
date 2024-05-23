//
//  InviteUsersViewModel.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 18.05.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

final class InviteUsersViewModel: ObservableObject {
    @Published var isLinkEnabled: Bool = true
    @Published var selectedAccessRight: ASCShareAccess = .none
    @Published var link: String = ""
    @Published var isLoading: Bool = false

    @Published var isAddUsersScreenDisplaying: Bool = false

    let room: ASCRoom

    private var cancellables = Set<AnyCancellable>()

    init(
        isLinkEnabled: Bool,
        selectedAccessRight: ASCShareAccess,
        link: String,
        isLoading: Bool,
        room: ASCRoom
    ) {
        self.isLinkEnabled = isLinkEnabled
        self.selectedAccessRight = selectedAccessRight
        self.link = link
        self.isLoading = isLoading
        self.room = room
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
    }

    func fetchData() {}
    private func changeLinkAccess(newAccess: ASCShareAccess) {
        service.setExternalLinkAccess(
            linkId: externalLink?.id,
            room: room,
            settingAccess: newAccess
        ) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async { [self] in
                switch result {
                case let .success(externalLink):
                    if let externalLink {
                        self.linkStr = externalLink.link
                        self.selectedAccessRight = externalLink.access
                        self.externalLink = externalLink
                    } else {
                        self.externalLink = nil
                        self.preventToggleAction = true
                        self.isExternalLinkSwitchActive = false
                    }
                case let .failure(error):
                    print("===", error.localizedDescription)
                    self.preventToggleAction = true
                    self.isExternalLinkSwitchActive.toggle()
                    log.error(error.localizedDescription, error)
                }
            }
        }
    }
}
