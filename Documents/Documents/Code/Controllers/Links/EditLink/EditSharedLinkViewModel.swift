//
//  EditSharedLinkViewModel.swift
//  Documents-opensource
//
//  Created by Lolita Chernysheva on 05.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Combine
import SwiftUI

final class EditSharedLinkViewModel: ObservableObject {
    @Published var sharingLinkURL: URL? = nil
    @Published var linkAccess: LinkAccess
    @Published var isExpired: Bool = false

    private var link: SharedSettingsLinkResponceModel?

    init(inputLink: SharedSettingsLinkResponceModel) {
        link = inputLink
        let linkInfo = inputLink.sharedTo
        isExpired = linkInfo.isExpired
        linkAccess = linkInfo.isInternal ? .docspaceUserOnly : .anyoneWithLink
        sharingLinkURL = URL(string: linkInfo.shareLink)
    }
}
