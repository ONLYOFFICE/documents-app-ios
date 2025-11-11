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
    @Published var isRevoking: Bool = false
    @Published var isRevoked: Bool = false
    @Published var isSaving: Bool = false
    @Published var isSaved: Bool = false
    @Published var resultModalModel: ResultViewModel?
    @Published var errorMessage: String? = nil
    @Published var isReadyToDismissed: Bool = false
    @Published var selectedAccessRight: ASCShareAccess = .none

    var accessMenuItems: [MenuViewItem] {
        [
            ASCShareAccess.editing,
            ASCShareAccess.review,
            ASCShareAccess.comment,
            ASCShareAccess.read,
        ].map { access in
            MenuViewItem(text: access.title(), customImage: access.swiftUIImage) { [unowned self] in
                selectedAccessRight = access
            }
        }
    }

    var isDeletePossible: Bool {
        if (room.roomType == .public && link?.isGeneral == true) || room.roomType == .fillingForm {
            return false
        }
        if sharingLink == nil {
            return false
        }
        return true
    }

    var isRevokePossible: Bool {
        if (room.roomType == .public && link?.isGeneral == true) || room.roomType == .fillingForm {
            return true
        } else {
            return false
        }
    }

    var isPossibleToSave: Bool {
        !linkName.isEmpty && selectedDate > Date() && !isSaving
    }

    var roomType: ASCRoomType?

    var isEditAccessPossible: Bool {
        link?.canEditAccess == true
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
        roomType = room.roomType
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
        selectedAccessRight = link?.access ?? .none
        defineSharingLink()
    }
}

// MARK: Handlers

extension RoomSharingCustomizeLinkViewModel {
    func onDelete() async {
        guard let linkId, var link = link ?? outputLink else { return }
        isDeleting = true
        do {
            try await linkAccessService.removeLink(
                id: linkId,
                title: link.linkInfo.title,
                linkType: link.linkInfo.linkType,
                password: link.linkInfo.password,
                room: room
            )
            isDeleting = false
            link.access = .none
            outputLink = link
            isDeleted = true
            isReadyToDismissed = true
        } catch {
            isDeleting = false
            log.error(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }

    func onSave() async -> String? {
        if isProtected, !isPasswordValid(password) {
            return .passwordErrorAlertMessage
        }

        guard isPossibleToSave else { return nil }

        await saveCurrentState()

        return nil
    }

    func onRevoke() async {
        guard let linkId,
              var link = link ?? outputLink else { return }
        isRevoking = true
        do {
            try await linkAccessService.revokeLink(
                id: linkId,
                title: link.linkInfo.title,
                linkType: link.linkInfo.linkType,
                password: link.linkInfo.password,
                room: room,
                denyDownload: isRestrictCopyOn
            )
            isRevoking = false
            link.access = .none
            outputLink = link
            isRevoked = true
            isReadyToDismissed = true
        } catch {
            isRevoking = false
            log.error(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: Private

private extension RoomSharingCustomizeLinkViewModel {
    @MainActor
    func saveCurrentState() async {
        isSaving = true
        do {
            let link = try await linkAccessService.changeOrCreateLink(
                id: linkId,
                title: linkName,
                access: selectedAccessRight.rawValue,
                expirationDate: isTimeLimited ? Self.sendDateFormatter.string(from: selectedDate) : nil,
                linkType: ASCShareLinkType.external,
                denyDownload: isRestrictCopyOn,
                password: isProtected ? password : nil,
                room: room
            )
            isSaving = false
            UIPasteboard.general.string = link.linkInfo.shareLink
            outputLink = link
            defineSharingLink()
            if isExpired, selectedDate > Date() {
                isExpired = false
            }
            resultModalModel = .init(result: .success, message: .linkCopiedSuccessfull)
            isSaved = true
            try await Task.sleep(nanoseconds: UInt64(Double.dismissAfterSeconds) * 1_000_000_000)
            isReadyToDismissed = true
        } catch {
            isSaving = false
            log.error(error.localizedDescription)
            errorMessage = error.localizedDescription
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

extension RoomSharingCustomizeLinkViewModel {
    func isPasswordValid(_ password: String) -> Bool {
        guard password.count >= 8 else { return false }

        let pattern = "^[a-zA-Z0-9!\"№%&'()*+,-./:;<=>?@\\[\\]^_`{|}~]+$"

        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }

        let range = NSRange(location: 0, length: password.utf16.count)
        return regex.firstMatch(in: password, options: [], range: range) != nil
    }
}
