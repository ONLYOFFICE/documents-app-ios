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
    let contentState: LinkSettingsContentState

    @Published var linkName: String = ""
    @Published var isProtected: Bool = false
    @Published var isRestrictCopyOn: Bool = false
    @Published var isTimeLimited: Bool = false
    @Published var selectedDate: Date
    @Published var password: String = ""
    @Published var isExpired: Bool = false

    @Published var sharingLink: URL? = nil
    @Published var isPasswordVisible: Bool = false
    @Published var isDeleting: Bool = false
    @Published var isDeleted: Bool = false
    @Published var isSaving: Bool = false
    @Published var isSaved: Bool = false
    @Published var resultModalModel: ResultViewModel?
    @Published var errorMessage: String? = nil

    var isDeletePossible: Bool {
        if room.roomType == .public, link?.isGeneral == true {
            return false
        }
        if sharingLink == nil {
            return false
        }
        return true
    }

    var isPossibleToSave: Bool {
        !linkName.isEmpty && selectedDate > Date() && !isSaving
    }

    private var cancelable = Set<AnyCancellable>()

    private var linkId: String? {
        link?.linkInfo.id ?? outputLink?.linkInfo.id
    }

    private let link: RoomSharingLinkModel?
    private let room: ASCRoom

    @Binding private var outputLink: RoomSharingLinkModel?

    private var linkAccessService = ServicesProvider.shared.roomSharingLinkAccesskService

    init(
        room: ASCRoom,
        inputLink: RoomSharingLinkModel? = nil,
        outputLink: Binding<RoomSharingLinkModel?>
    ) {
        link = inputLink
        self.room = room
        _outputLink = outputLink
        let linkInfo = link?.linkInfo
        selectedDate = {
            guard let dateString = linkInfo?.expirationDate else {
                return Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            }
            return Self.dateFormatter.date(from: dateString) ?? Date()
        }()
        linkName = linkInfo?.title ?? ""
        contentState = link?.isGeneral == true ? .general : .additional
        password = linkInfo?.password ?? ""
        isExpired = linkInfo?.isExpired ?? false
        isProtected = !password.isEmpty
        isRestrictCopyOn = linkInfo?.denyDownload == true
        isTimeLimited = linkInfo?.expirationDate != nil

        defineSharingLink()
    }
}

// MARK: Handlers

extension RoomSharingCustomizeLinkViewModel {
    func onDelete() {
        guard let linkId, var link = link ?? outputLink else { return }
        isDeleting = true
        linkAccessService.removeLink(
            id: linkId,
            title: link.linkInfo.title,
            linkType: link.linkInfo.linkType,
            password: link.linkInfo.password,
            room: room
        ) { [self] error in
            isDeleting = false
            guard error == nil else {
                log.error(error?.localizedDescription ?? "")
                errorMessage = error?.localizedDescription
                return
            }
            link.access = .none
            outputLink = link
            isDeleted = true
        }
    }

    func onSave() {
        guard isPossibleToSave else { return }
        saveCurrentState()
    }
}

// MARK: Private

private extension RoomSharingCustomizeLinkViewModel {
    func saveCurrentState() {
        isSaving = true
        linkAccessService.changeOrCreateLink(
            id: linkId,
            title: linkName,
            access: .defaultAccsessForLink,
            expirationDate: isTimeLimited ? Self.sendDateFormatter.string(from: selectedDate) : nil,
            linkType: ASCShareLinkType.external,
            denyDownload: isRestrictCopyOn,
            password: isProtected ? password : nil,
            room: room
        ) { [self] result in
            switch result {
            case let .success(link):
                DispatchQueue.main.async { [self] in
                    isSaving = false
                    outputLink = link
                    defineSharingLink()
                    if isExpired, selectedDate > Date() {
                        isExpired = false
                    }
                    isSaved = true
                }
            case let .failure(error):
                DispatchQueue.main.async { [self] in
                    isSaving = false
                    log.error(error.localizedDescription)
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    func defineSharingLink() {
        guard let strLink = link?.linkInfo.shareLink ?? outputLink?.linkInfo.shareLink,
              link?.linkInfo.isExpired != true
        else { return }
        sharingLink = URL(string: strLink)
    }
}

// MARK: Date formaters

private extension RoomSharingCustomizeLinkViewModel {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static let sendDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

private extension Int {
    static let textFiesldDeboundsSeconds = 1
    static let defaultAccsessForLink = ASCShareAccess.read.rawValue
}

private extension String {
    static let linkCopiedSuccessfull = NSLocalizedString("Link successfully\ncopied to clipboard", comment: "")
    static let linkAndPasswordCopiedSuccessfull = NSLocalizedString("Link and password\nsuccessfully copied\nto clipboard", comment: "")
}
