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
    @Published var selectedAccessRight: ASCShareAccess = .none

    // MARK: - Public vars

    var accessMenuItems: [MenuViewItem] {
        [
            ASCShareAccess.editing,
            ASCShareAccess.review,
            ASCShareAccess.comment,
            ASCShareAccess.read,
            ASCShareAccess.deny,
        ].map { access in
            MenuViewItem(text: access.title(), customImage: access.swiftUIImage) { [unowned self] in
                setAccessRight(access)
            }
        }
    }

    var linkLifeTimeMenuItems: [MenuViewItem] {
        [
            LinkLifeTimeOption.twelveHours,
            LinkLifeTimeOption.oneDay,
            LinkLifeTimeOption.sevenDays,
            LinkLifeTimeOption.unlimited,
            LinkLifeTimeOption.custom,
        ].map { option in
            MenuViewItem(text: option.localized) { [unowned self] in
                setLinkLifeTime(option: option)
            }
        }
    }

    // MARK: - Private vars

    private var link: SharedSettingsLinkResponceModel?
    private var file: ASCFile
    private var service: NetworkManagerSharedSettingsProtocol = NetworkManagerSharedSettings()

    // MARK: - init

    init(file: ASCFile, inputLink: SharedSettingsLinkResponceModel) {
        link = inputLink
        let linkInfo = inputLink.sharedTo
        isExpired = linkInfo.isExpired
        linkAccess = linkInfo.isInternal ? .docspaceUserOnly : .anyoneWithLink
        sharingLinkURL = URL(string: linkInfo.shareLink)
        self.file = file
        selectedAccessRight = ASCShareAccess(inputLink.access)
    }

    private func setAccessRight(_ accessRight: ASCShareAccess) {
        changeLink(
            access: accessRight,
            isInternal: linkAccess == .docspaceUserOnly
        )
    }

    func setLinkType() {
        changeLink(isInternal: linkAccess == .docspaceUserOnly ? false : true)
    }

    private func changeLink(
        access: ASCShareAccess? = nil,
        isInternal: Bool
    ) {
        guard let link = link else { return }
        let linkInfo = link.sharedTo
        let requestModel = EditSharedLinkRequestModel(
            linkId: linkInfo.id,
            access: access?.rawValue ?? selectedAccessRight.rawValue,
            primary: linkInfo.primary,
            isInternal: isInternal,
            expirationDate: linkInfo.expirationDate
        )

        service.setLinkAccess(file: file, requestModel: requestModel) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(result):
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    linkAccess = result.sharedTo.isInternal ? .docspaceUserOnly : .anyoneWithLink
                    sharingLinkURL = URL(string: result.sharedTo.shareLink)
                    // TODO: isExpired =
                    selectedAccessRight = ASCShareAccess(rawValue: result.access) ?? .none
                }

            case let .failure(error):
                print(error.localizedDescription)
            }
        }
    }

    private func setLinkLifeTime(option: LinkLifeTimeOption) {}
}
