//
//  EditSharedLinkViewModel.swift
//  Documents-opensource
//
//  Created by Lolita Chernysheva on 05.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Combine
import MBProgressHUD
import SwiftUI

final class EditSharedLinkViewModel: ObservableObject {
    @Published var sharingLinkURL: URL? = nil
    @Published var linkAccess: LinkAccess
    @Published var isExpired: Bool = false
    @Published var selectedAccessRight: ASCShareAccess = .none
    @Published var selectedDate: Date?
    @Published var expirationDateString: String?
    @Published var linkLifeTimeString: String
    @Published var selectedLinkLifeTimeOption: LinkLifeTimeOption = .sevenDays

    private let networkService = NetworkManagerSharedSettings()

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
    private var onRemoveCompletion: (() -> Void)?
    @Binding var outputLink: SharedSettingsLinkResponceModel?

    // MARK: - init

    init(
        file: ASCFile,
        inputLink: SharedSettingsLinkResponceModel,
        outputLink: Binding<SharedSettingsLinkResponceModel?>,
        onRemoveCompletion: (() -> Void)?
    ) {
        link = inputLink
        _outputLink = outputLink
        self.onRemoveCompletion = onRemoveCompletion
        let linkInfo = inputLink.sharedTo
        isExpired = linkInfo.isExpired
        linkAccess = linkInfo.linkAccess
        sharingLinkURL = URL(string: linkInfo.shareLink)
        self.file = file
        selectedAccessRight = ASCShareAccess(inputLink.access)
        selectedDate = {
            guard let dateString = linkInfo.expirationDate else {
                return nil
            }
            return Self.dateFormatter.date(from: dateString)
        }()

        expirationDateString = linkInfo.expirationDate
        linkLifeTimeString = linkInfo.expirationDate ?? NSLocalizedString("Unlimited", comment: "")
        updatelinkLifeTimeLimitString()
    }

    private func setAccessRight(_ accessRight: ASCShareAccess) {
        changeLink(
            access: accessRight,
            isInternal: linkAccess.isInternal
        )
    }

    func buildViewModel() {
        guard let link = link else { return }
        let linkInfo = link.sharedTo
        isExpired = linkInfo.isExpired
        linkAccess = linkInfo.linkAccess
        sharingLinkURL = URL(string: linkInfo.shareLink)
        selectedAccessRight = ASCShareAccess(link.access)
        selectedDate = {
            guard let dateString = linkInfo.expirationDate else {
                return nil
            }
            return Self.dateFormatter.date(from: dateString)
        }()
        expirationDateString = linkInfo.expirationDate
        linkLifeTimeString = linkInfo.expirationDate ?? NSLocalizedString("Unlimited", comment: "")
        updatelinkLifeTimeLimitString()
    }

    func didDateChangedManualy() {
        setLinkLifeTime(option: .custom)
    }

    func setLinkType(linkAccess: LinkAccess) {
        changeLink(isInternal: linkAccess.isInternal)
    }

    func removeLink(completion: @escaping () -> Void) {
        changeLink(access: ASCShareAccess.none, isInternal: linkAccess.isInternal) {
            DispatchQueue.main.async { [weak self] in
                self?.onRemoveCompletion?()
                completion()
            }
        }
    }

    func copyLink() {
        let hud = MBProgressHUD.showTopMost()
        if let sharingLinkURL {
            UIPasteboard.general.string = sharingLinkURL.absoluteString
            hud?.setState(result: .success(NSLocalizedString("Link successfully\ncopied to clipboard", comment: "Button title")))

        } else {
            hud?.setState(result: .failure(nil))
        }

        hud?.hide(animated: true, afterDelay: .standardDelay)
    }

    func regenerateLink() {
        guard let link = link,
              let expiration = Calendar.current.date(byAdding: .day, value: 7, to: Date()) else { return }

        expirationDateString = Self.sendDateFormatter.string(from: expiration)

        let requestModel = EditSharedLinkRequestModel(
            linkId: link.sharedTo.id,
            access: link.access,
            primary: link.sharedTo.primary,
            isInternal: link.sharedTo.isInternal,
            expirationDate: expirationDateString
        )

        networkService.regenerateLink(file: file, requestModel: requestModel) { result in
            switch result {
            case let .success(link):
                self.link = link
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.buildViewModel()
                }
            case let .failure(error):
                print(error.localizedDescription)
            }
        }
    }

    private func changeLink(
        access: ASCShareAccess? = nil,
        isInternal: Bool,
        completion: (() -> Void)? = nil
    ) {
        guard let link = link else { return }
        let linkInfo = link.sharedTo
        let requestModel = EditSharedLinkRequestModel(
            linkId: linkInfo.id,
            access: access?.rawValue ?? selectedAccessRight.rawValue,
            primary: linkInfo.primary,
            isInternal: isInternal,
            expirationDate: expirationDateString
        )

        service.setLinkAccess(file: file, requestModel: requestModel) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(result):
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    linkAccess = result.sharedTo.linkAccess
                    sharingLinkURL = URL(string: result.sharedTo.shareLink)
                    selectedAccessRight = ASCShareAccess(rawValue: result.access) ?? .none
                    expirationDateString = result.sharedTo.expirationDate
                    outputLink = result
                    completion?()
                }
            case let .failure(error):
                print(error.localizedDescription)
                completion?()
            }
        }
    }

    private func setLinkLifeTime(option: LinkLifeTimeOption) {
        selectedLinkLifeTimeOption = option
        switch option {
        case .twelveHours:
            if let expiration = Calendar.current.date(byAdding: .hour, value: 12, to: Date()) {
                expirationDateString = Self.sendDateFormatter.string(from: expiration)
            }
        case .oneDay:
            if let expiration = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
                expirationDateString = Self.sendDateFormatter.string(from: expiration)
            }
        case .sevenDays:
            if let expiration = Calendar.current.date(byAdding: .day, value: 7, to: Date()) {
                expirationDateString = Self.sendDateFormatter.string(from: expiration)
            }
        case .unlimited:
            expirationDateString = nil
        case .custom:
            if let selectedDate {
                expirationDateString = Self.sendDateFormatter.string(from: selectedDate)
            }
        }
        updatelinkLifeTimeLimitString()
        changeLink(isInternal: linkAccess.isInternal)
    }

    private func updatelinkLifeTimeLimitString() {
        guard let expirationDateString else {
            if selectedLinkLifeTimeOption == .unlimited {
                linkLifeTimeString = NSLocalizedString("Unlimited", comment: "")
            }
            return
        }

        let expirationString = expirationDateString
        let now = Date()

        let expirationDate = Self.dateFormatter.date(from: expirationString)

        guard let timeInterval = expirationDate?.timeIntervalSince(now) else { return }

        if timeInterval < 0 {
            linkLifeTimeString = NSLocalizedString("Expired", comment: "Expiration status")
            isExpired = true
        } else if timeInterval < 24 * 60 * 60 {
            let hours = Int(timeInterval / 3600)
            linkLifeTimeString = String(format: NSLocalizedString("%d hours", comment: "Hours left"), hours)
            isExpired = false
        } else {
            let days = Int(timeInterval / (24 * 60 * 60))
            linkLifeTimeString = String(format: NSLocalizedString("%d days", comment: "Days left"), days)
            isExpired = false
        }
    }
}

// MARK: Date formaters

private extension EditSharedLinkViewModel {
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
