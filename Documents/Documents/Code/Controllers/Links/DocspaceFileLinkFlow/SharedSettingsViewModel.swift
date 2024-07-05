//
//  SharedSettingsViewModel.swift
//  Documents-opensource
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

    @Published var isShared: Bool
    @Published var links: [SharedSettingsLinkRowModel] = []
    @Published var isDocspaceUserOnly: Bool = false
    @Published var selectdLink: SharedSettingsLinkResponceModel?

    init(file: ASCFile) {
        self.file = file
        isShared = file.shared
        loadLinks()
        buildViewModel()
    }

    func createAndCopySharedLink() {
        networkService.createAndCopy(file: file) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(link):
                self.flowModel.links = [link]
                DispatchQueue.main.async {
                    self.isShared = true
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
        let expirationInfo = calculateExpirationInfo(expirationDateString: link.sharedTo.expirationDate)
        return SharedSettingsLinkRowModel(
            id: link.sharedTo.id,
            linkAccess: link.sharedTo.isInternal ? .docspaceUserOnly : .anyoneWithLink,
            expiredTo: "",
            rights: ASCShareAccess(rawValue: link.access)?.title() ?? "",
            isExpired: link.sharedTo.isExpired,
            expirationInfo: expirationInfo,
            onTapAction: { [weak self] in
                guard let self else { return }
                self.selectdLink = link
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

    private func calculateExpirationInfo(expirationDateString: String?) -> String {
        guard let expirationDateString = expirationDateString,
              let expirationDate = SharedSettingsViewModel.dateFormatter.date(from: expirationDateString)
        else {
            return NSLocalizedString("Unlimited", comment: "")
        }

        guard let interval = expirationService.getExpirationInterval(expirationDateString: expirationDateString) else {
            return ""
        }

        switch interval {
        case .expired:
            return NSLocalizedString("The link has expired", comment: "Expiration status")
        case let .days(days):
            return String(format: NSLocalizedString("Expires after %d days", comment: "Days left"), days)
        case let .hours(hours):
            return String(format: NSLocalizedString("Expires after %d hours", comment: "Hours left"), hours)
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
