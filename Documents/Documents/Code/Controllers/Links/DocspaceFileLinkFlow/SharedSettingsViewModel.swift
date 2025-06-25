//
//  SharedSettingsViewModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 01.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation
import MBProgressHUD
import SwiftUI

struct LinksFlowModel {
    var links: [SharedSettingsLinkResponceModel] = []
}

final class SharedSettingsViewModel: ObservableObject {
    let file: ASCFile
    let linksLimit = 6
    private let networkService = NetworkManagerSharedSettings()
    private(set) var flowModel = LinksFlowModel()
    private let expirationService = ExpirationLinkDateService()
    private(set) var sharingLink: URL?

    @Published var isShared: Bool
    @Published var links: [SharedSettingsLinkRowModel] = []
    @Published var isDocspaceUserOnly: Bool = false
    @Published var selectdLink: SharedSettingsLinkResponceModel?
    @Published var isSharingScreenPresenting: Bool = false

    init(file: ASCFile) {
        self.file = file
        isShared = file.shared
        buildViewModel()
        loadLinks()
    }

    func createAndCopySharedLink() {
        let requestModel = CreateAndCopyLinkRequestModel(access: ASCShareAccess.read.rawValue, expirationDate: nil, isInternal: false)

        networkService.createAndCopy(file: file, requestModel: requestModel) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(link):
                self.flowModel.links = [link]
                DispatchQueue.main.async {
                    self.isShared = true
                    self.file.shared = true
                    self.buildViewModel()
                }
                let hud = MBProgressHUD.showTopMost()
                UIPasteboard.general.string = link.sharedTo.shareLink
                hud?.setState(result: .success(NSLocalizedString("Link successfully\ncopied to clipboard", comment: "Button title")))
                hud?.hide(animated: true, afterDelay: .standardDelay)

            case let .failure(error):
                print(error.localizedDescription)
            }
        }
    }

    func addLink() {
        let requestModel = AddSharedLinkRequestModel(access: ASCShareAccess.read.rawValue, primary: false, isInternal: false)
        networkService.addLink(file: file, requestModel: requestModel) { result in
            switch result {
            case let .success(link):
                self.flowModel.links.append(link)
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.buildViewModel()
                }
            case let .failure(error):
                print(error.localizedDescription)
            }
        }
    }

    func loadLinks() {
        networkService.fetchFileLinks(file: file) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(links):
                self.flowModel.links = links
                self.buildViewModel()
            case let .failure(error):
                print(error.localizedDescription)
            }
        }
    }

    func buildViewModel() {
        links = flowModel.links.map { self.mapToLinkViewModel(link: $0) }
    }

    func mapToLinkViewModel(link: SharedSettingsLinkResponceModel) -> SharedSettingsLinkRowModel {
        var isTimeLimited = link.sharedTo.expirationDate != nil
        var isSharingPossible: Bool = !link.sharedTo.isExpired
        return SharedSettingsLinkRowModel(
            id: link.sharedTo.id,
            linkAccess: link.sharedTo.isInternal ? .docspaceUserOnly : .anyoneWithLink,
            expiredTo: "",
            rights: ASCShareAccess(rawValue: link.access)?.title() ?? "",
            rightsImage: ASCShareAccess(rawValue: link.access)?.swiftUIImage ?? Image(""),
            isExpired: link.sharedTo.isExpired,
            isTimeLimited: isTimeLimited,
            onTapAction: { [weak self] in
                guard let self else { return }
                self.selectdLink = link
            },
            onShareAction: { [weak self] in
                guard let self, isSharingPossible else { return }
                isSharingScreenPresenting = true
                sharingLink = URL(string: link.sharedTo.shareLink)
            }
        )
    }

    func handleLinkOutChanges(link: SharedSettingsLinkResponceModel?) {
        if let link, let index = flowModel.links.firstIndex(where: { $0.sharedTo.id == link.sharedTo.id }) {
            selectdLink = link
            flowModel.links[index] = link
            buildViewModel()
        }
    }
}

private extension SharedSettingsViewModel {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    static let sendDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}
