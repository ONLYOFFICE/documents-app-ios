//
//  RoomSharingCustomizeLinkViewModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 03.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Combine
import SwiftUI

enum EditSharedLinkEntityType {
    case room(ASCRoom)
    case folder(ASCFolder)
    case file(ASCFile)
}

struct EditSharedLinkModel {
    var linkName: String = ""
    var isProtected: Bool = false
    var isRestrictCopyOn: Bool = false
    var isTimeLimited: Bool = false
    var selectedDate: Date
    var password: String = ""
    var isExpired: Bool = false
    var selectedAccessRight: ASCShareAccess = .none
    var whoHasAccess: LinkAccess = .anyoneWithLink

    static let empty = EditSharedLinkModel(linkName: "", isProtected: false, isRestrictCopyOn: false, isTimeLimited: false, selectedDate: Date(), password: "", isExpired: false, selectedAccessRight: .none)
}

struct EditSharedLinkScreenModel {
    var isPasswordVisible: Bool = false
    var isDeleting: Bool = false
    var isDeleted: Bool = false
    var isRevoking: Bool = false
    var isRevoked: Bool = false
    var isSaving: Bool = false
    var isSaved: Bool = false
    var isReadyToDismissed: Bool = false

    static let empty = EditSharedLinkScreenModel(isPasswordVisible: false, isDeleting: false, isDeleted: false, isRevoking: false, isRevoked: false, isSaving: false, isSaved: false, isReadyToDismissed: false)
}

enum LinkSettingsContentState {
    case general
    case additional
}

final class EditSharedLinkViewModel: ObservableObject {
    private var entity: EditSharedLinkEntityType
    private var editSharedLinkService: EditSharedLinkServiceProtocol?
    private var viewService: EditSharedLnkViewService?

    let contentState: LinkSettingsContentState

    @Published var linkModel: EditSharedLinkModel = .empty
    @Published var screenModel: EditSharedLinkScreenModel = .empty

    @Published var sharingLinkURL: URL? = nil
    @Published var resultModalModel: ResultViewModel?
    @Published var errorMessage: String? = nil

    var accessMenuItems: [MenuViewItem] {
        [
            ASCShareAccess.editing,
            ASCShareAccess.review,
            ASCShareAccess.comment,
            ASCShareAccess.read,
        ].map { access in
            MenuViewItem(text: access.title(), customImage: access.swiftUIImage) { [unowned self] in
                linkModel.selectedAccessRight = access
            }
        }
    }

    var isDeletePossible: Bool {
        viewService?.isDeletePossible ?? false
    }

    var showRestrictCopySection: Bool {
        viewService?.showRestrictCopySection ?? false
    }

    var isPossibleToSave: Bool {
        !linkModel.linkName.isEmpty && linkModel.selectedDate > Date() && !screenModel.isSaving
    }

    var isEditAccessPossible: Bool {
        viewService?.isEditAccessPossible ?? false
    }
    
    var showWhoHasAccessSection: Bool {
        viewService?.showWhoHasAccessSection ?? false
    }

    var showTimeLimit: Bool {
        link.linkInfo.primary == false
    }

    var isFileOrFolderVDRoomWithDenyDownload: Bool {
        switch entity {
        case let .folder(folder):
            guard
                folder.rootFolderType == .virtualRooms,
                let room = folder.parent
            else {
                return false
            }
            return room.denyDownload

        case let .file(file):
            guard
                file.rootFolderType == .virtualRooms,
                let room = file.parent
            else {
                return false
            }
            return room.denyDownload

        case .room:
            return false
        }
    }

    private var cancelable = Set<AnyCancellable>()

    private var linkId: String? {
        link.linkInfo.id
    }

    private let link: SharingInfoLinkModel

    @Binding private var outputLink: SharingInfoLinkModel?

    init(
        entity: EditSharedLinkEntityType,
        inputLink: SharingInfoLinkModel,
        outputLink: Binding<SharingInfoLinkModel?>
    ) {
        link = inputLink
        self.entity = entity
        editSharedLinkService = EditSharedLinkService(entity: entity)
        viewService = EditSharedLnkViewService(entity: entity, link: link)

        _outputLink = outputLink
        contentState = link.isGeneral == true ? .general : .additional

        linkModel = EditSharedLinkModel(
            linkName: link.linkInfo.title,
            isProtected: !linkModel.password.isEmpty,
            isRestrictCopyOn: isRestrictCopyOn(),
            isTimeLimited: link.linkInfo.expirationDate != nil,
            selectedDate: {
                guard let dateString = link.linkInfo.expirationDate else {
                    return Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
                }
                return Self.dateFormatter.date(from: dateString) ?? Date()
            }(),
            password: link.linkInfo.password ?? "",
            isExpired: link.linkInfo.isExpired,
            selectedAccessRight: link.access,
            whoHasAccess: link.linkInfo.internal ? .docspaceUserOnly : .anyoneWithLink
        )

        defineSharingLink()
    }
}

// MARK: Handlers

extension EditSharedLinkViewModel {
    @MainActor
    func onDelete() async {
        var link = link
        screenModel.isDeleting = true
        do {
            try await editSharedLinkService?.delete(
                id: link.linkInfo.id,
                title: link.linkInfo.title,
                linkType: link.linkInfo.linkType,
                password: link.linkInfo.password
            )
            screenModel.isDeleting = false
            link.access = .none
            outputLink = link
            screenModel.isDeleted = true
            screenModel.isReadyToDismissed = true
        } catch {
            screenModel.isDeleting = false
            log.error(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }

    func onSave() async -> String? {
        if linkModel.isProtected, !isPasswordValid(linkModel.password) {
            return .passwordErrorAlertMessage
        }

        guard isPossibleToSave else { return nil }

        await saveCurrentState()

        return nil
    }

    @MainActor
    func onRevoke() async {
        guard let linkId else { return }
        var link = link
        screenModel.isRevoking = true
        do {
            try await editSharedLinkService?.revoke(
                id: linkId,
                denyDownload: link.linkInfo.denyDownload,
                title: link.linkInfo.title,
                linkType: link.linkInfo.linkType,
                password: link.linkInfo.password
            )
            screenModel.isRevoking = false
            link.access = .none
            outputLink = link
            screenModel.isRevoked = true
            screenModel.isReadyToDismissed = true
        } catch {
            screenModel.isRevoking = false
            log.error(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: Private

private extension EditSharedLinkViewModel {
    @MainActor
    func saveCurrentState() async {
        screenModel.isSaving = true
        do {
            let link = try await editSharedLinkService?.editLink(
                id: linkId,
                title: linkModel.linkName,
                access: linkModel.selectedAccessRight.rawValue,
                expirationDate: linkModel.isTimeLimited ? Self.sendDateFormatter.string(from: linkModel.selectedDate) : nil,
                linkType: ASCShareLinkType.external,
                denyDownload: linkModel.isRestrictCopyOn,
                password: linkModel.isProtected ? linkModel.password : nil,
                isInternal: linkModel.whoHasAccess == .docspaceUserOnly
            )
            screenModel.isSaving = false
            UIPasteboard.general.string = link?.linkInfo.shareLink
            outputLink = link
            defineSharingLink()
            if linkModel.isExpired, linkModel.selectedDate > Date() {
                linkModel.isExpired = false
            }
            resultModalModel = .init(result: .success, message: .linkCopiedSuccessfull)
            screenModel.isSaved = true
            try await Task.sleep(nanoseconds: UInt64(Double.dismissAfterSeconds) * 1_000_000_000)
            screenModel.isReadyToDismissed = true
        } catch {
            screenModel.isSaving = false
            log.error(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }

    func defineSharingLink() {
        guard link.linkInfo.isExpired != true else { return }
        sharingLinkURL = URL(string: link.linkInfo.shareLink)
    }

    func isRestrictCopyOn() -> Bool {
        link.linkInfo.denyDownload || isFileOrFolderVDRoomWithDenyDownload
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

private extension Double {
    static let dismissAfterSeconds: Double = 1.0
}

private extension Int {
    static let textFiesldDeboundsSeconds = 1
    static let defaultAccsessForLink = ASCShareAccess.read.rawValue
}

private extension String {
    static let linkCopiedSuccessfull = NSLocalizedString("Link successfully\ncopied to clipboard", comment: "")
    static let linkAndPasswordCopiedSuccessfull = NSLocalizedString("Link and password\nsuccessfully copied\nto clipboard", comment: "")
    static let passwordErrorAlertMessage = NSLocalizedString(
        "Password must contain: Minimum length: 8 Allowed characters: a-z, A-Z, 0-9, !\"№%&'()*+,-./:;<=>?@[\\]^_`{|}~",
        comment: ""
    )
}

extension EditSharedLinkViewModel {
    func isPasswordValid(_ password: String) -> Bool {
        guard password.count >= 8 else { return false }

        let pattern = "^[a-zA-Z0-9!\"№%&'()*+,-./:;<=>?@\\[\\]^_`{|}~]+$"

        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }

        let range = NSRange(location: 0, length: password.utf16.count)
        return regex.firstMatch(in: password, options: [], range: range) != nil
    }
}
