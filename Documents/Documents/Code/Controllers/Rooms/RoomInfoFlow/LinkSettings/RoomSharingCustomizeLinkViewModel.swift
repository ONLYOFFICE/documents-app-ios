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
    @Published var isProtected: Bool = false
    @Published var isRestrictCopyOn: Bool = false
    @Published var isTimeLimited: Bool = false
    @Published var selectedDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @Published var password: String
    @Published var contentState: LinkSettingsContentState

    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSXXXXX"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private var cancelable = Set<AnyCancellable>()

    private(set) var link: RoomSharingLinkModel?
    private let room: ASCRoom

    private var linkAccessService = ServicesProvider.shared.roomSharingLinkAccesskService

    init(
        room: ASCRoom,
        link: RoomSharingLinkModel? = nil
    ) {
        self.room = room
        self.link = link
        contentState = link?.isGeneral == false ? .additional : .general
        password = link?.linkInfo.password ?? ""
        isProtected = !password.isEmpty
        isRestrictCopyOn = link?.linkInfo.denyDownload == true
        isTimeLimited = link?.linkInfo.expirationDate != nil

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

// MARK: Private

private extension RoomSharingCustomizeLinkViewModel {
    func saveCurrentState() {
        linkAccessService.changeOrCreateLink(
            id: link?.linkInfo.id,
            title: link?.linkInfo.title ?? "link",

            access: 2, // MARK: TODO

            expirationDate: isTimeLimited ? dateFormatter.string(from: selectedDate) : nil,

            linkType: 1, // MARK: TODO

            denyDownload: isRestrictCopyOn,
            password: isProtected ? password : nil,
            room: room
        ) { result in
            switch result {
            case let .success(link):
                self.link = link
            case let .failure(error):
                log.error(error.localizedDescription)
            }
        }
    }

    func copyLinkAndNotify() {
        copyLink()
        // notify
    }

    func copyLink() {}
}
