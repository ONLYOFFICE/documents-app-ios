//
//  RoomSharingCustomizeLinkViewModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 03.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Combine
import SwiftUI

enum LinkSettingsContentState {
    case general
    case additional
}

final class RoomSharingCustomizeLinkViewModel: ObservableObject {
    @Published var isProtected: Bool = false
    @Published var isRestrictCopyOn: Bool = false
    @Published var isTimeLimited: Bool = false
    @Published var password: String
    @Published var contentState: LinkSettingsContentState

    private var isCurrentStateSave = true

    private var cancelable = Set<AnyCancellable>()

    private var link: RoomSharingLinkModel?

    private var linkAccessService = ServicesProvider.shared.roomSharingLinkAccesskService

    // MARK: temp

    init(link: RoomSharingLinkModel?) {
        contentState = link?.isGeneral == false ? .additional : .general
        password = link?.linkInfo.password ?? ""
        isProtected = !password.isEmpty
        isRestrictCopyOn = link?.linkInfo.denyDownload == true
        isTimeLimited = link?.linkInfo.expirationDate != nil
    }
}

// MARK: Private

private extension RoomSharingCustomizeLinkViewModel {
    func saveCurrentState() {}

    func copyLinkAndNotify() {
        copyLink()
        // notify
    }

    func copyLink() {}
}
