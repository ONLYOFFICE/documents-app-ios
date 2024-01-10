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
    @Published var selectedDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @Published var password: String = ""

    @Published var isPasswordVisible: Bool = false
    @Published var isDeleting: Bool = false
    @Published var isDeleted: Bool = false
    @Published var resultModalModel: ResultViewModel?
    @Published var errorMessage: String? = nil

    var isDeletePossible: Bool {
        if room.roomType == .public, link?.isGeneral == true {
            return false
        }
        if link == nil && outputLink == nil {
            return false
        }
        return true
    }

    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSXXXXX"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

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
        linkName = linkInfo?.title ?? ""
        contentState = link?.isGeneral == true ? .general : .additional
        password = linkInfo?.password ?? ""
        isProtected = !password.isEmpty
        isRestrictCopyOn = linkInfo?.denyDownload == true
        isTimeLimited = linkInfo?.expirationDate != nil

        $linkName
            .dropFirst()
            .receive(on: RunLoop.main)
            .debounce(for: .seconds(.threeSeconds), scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.saveCurrentState()
            })
            .store(in: &cancelable)

        $isProtected
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in
                self?.saveCurrentState()
            })
            .store(in: &cancelable)

        $isRestrictCopyOn
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in
                self?.saveCurrentState()
            })
            .store(in: &cancelable)

        $isTimeLimited
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in
                self?.saveCurrentState()
            })
            .store(in: &cancelable)

        $selectedDate
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in
                self?.saveCurrentState()
            })
            .store(in: &cancelable)

        $password
            .dropFirst()
            .receive(on: RunLoop.main)
            .debounce(for: .seconds(.threeSeconds), scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.saveCurrentState()
            })
            .store(in: &cancelable)
    }
}

// MARK: Handlers

extension RoomSharingCustomizeLinkViewModel {
    func onCopyLinkAndNotify() {
        guard let link = link else { return }
        if password.isEmpty {
            UIPasteboard.general.string = link.linkInfo.shareLink
            resultModalModel = .init(
                result: .success,
                message: .linkCopiedSuccessfull
            )
        } else {
            UIPasteboard.general.string = """
            \(link.linkInfo.shareLink)
            \(password)
            """
            resultModalModel = .init(
                result: .success,
                message: .linkAndPasswordCopiedSuccessfull
            )
        }
    }

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
}

// MARK: Private

private extension RoomSharingCustomizeLinkViewModel {
    var isPossibleToSave: Bool {
        !linkName.isEmpty
    }

    func saveCurrentState() {
        guard isPossibleToSave else { return }
        linkAccessService.changeOrCreateLink(
            id: linkId,
            title: linkName,
            access: .defaultAccsessForLink,
            expirationDate: isTimeLimited ? dateFormatter.string(from: selectedDate) : nil,

            linkType: 1, // MARK: TODO

            denyDownload: isRestrictCopyOn,
            password: isProtected ? password : nil,
            room: room
        ) { [self] result in
            switch result {
            case let .success(link):
                outputLink = link
            case let .failure(error):
                log.error(error.localizedDescription)
                errorMessage = error.localizedDescription
            }
        }
    }
}

private extension Int {
    static let threeSeconds = 3
    static let defaultAccsessForLink = ASCShareAccess.read.rawValue
}

private extension String {
    static let linkCopiedSuccessfull = NSLocalizedString("Link successfully copied to clipboard", comment: "")
    static let linkAndPasswordCopiedSuccessfull = NSLocalizedString("Link and password successfully copied to clipboard", comment: "")
}
