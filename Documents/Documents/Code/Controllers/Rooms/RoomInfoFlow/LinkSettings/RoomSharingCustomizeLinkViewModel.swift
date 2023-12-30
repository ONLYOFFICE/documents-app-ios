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
    @Published var contentState: LinkSettingsContentState

    @Published var linkName: String
    @Published var isProtected: Bool = false
    @Published var isRestrictCopyOn: Bool = false
    @Published var isTimeLimited: Bool = false
    @Published var selectedDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @Published var password: String

    @Published var isPasswordVisible: Bool = false
    @Published var isDeleting: Bool = false
    @Published var isDeleted: Bool = false
    @Published var errorMessage: String?

    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSXXXXX"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private var cancelable = Set<AnyCancellable>()

    private let linkId: String?
    private let room: ASCRoom

    @Binding private var outputLink: RoomSharingLinkModel?

    private var linkAccessService = ServicesProvider.shared.roomSharingLinkAccesskService

    init(
        room: ASCRoom,
        inputLink: RoomSharingLinkModel?,
        outputLink: Binding<RoomSharingLinkModel?>
    ) {
        linkId = inputLink?.linkInfo.id
        self.room = room
        _outputLink = outputLink
        let link = inputLink
        let linkInfo = link?.linkInfo
        linkName = linkInfo?.title ?? ""
        contentState = link?.isGeneral == false ? .additional : .general
        password = linkInfo?.password ?? ""
        isProtected = !password.isEmpty
        isRestrictCopyOn = linkInfo?.denyDownload == true
        isTimeLimited = linkInfo?.expirationDate != nil

        $linkName
            .dropFirst()
            .receive(on: RunLoop.main)
            .debounce(for: .seconds(3), scheduler: DispatchQueue.main)
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
            .debounce(for: .seconds(3), scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.saveCurrentState()
            })
            .store(in: &cancelable)
    }
}

// MARK: Handlers

extension RoomSharingCustomizeLinkViewModel {
    func onCopyLinkAndNotify() {
        copyLink()
        notify()
    }

    func onDelete() {
        guard let linkId else { return }
        isDeleting = true
        linkAccessService.removeLink(id: linkId, room: room) { [self] result in
            isDeleting = false
            switch result {
            case let .success(link):
                outputLink = link
                isDeleted = true
            case let .failure(error):
                log.error(error.localizedDescription)
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: Private

private extension RoomSharingCustomizeLinkViewModel {
    func saveCurrentState() {
        linkAccessService.changeOrCreateLink(
            id: linkId,
            title: linkName,

            access: 2, // MARK: TODO

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

    func copyLink() {}

    func notify() {}
}
