//
//  InviteUsersViewModel.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 18.05.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

final class InviteUsersViewModel: ObservableObject {
    @Published var isLinkEnabled: Bool = true
    @Published var selectedAccessRight: ASCShareAccess = .none
    @Published var link: String = ""
    @Published var isLoading: Bool = false

    @Published var isAddUsersScreenDisplaying: Bool = false

    let room: ASCRoom

    private var cancellables = Set<AnyCancellable>()

    init(
        isLinkEnabled: Bool,
        selectedAccessRight: ASCShareAccess,
        link: String,
        isLoading: Bool,
        room: ASCRoom
    ) {
        self.isLinkEnabled = isLinkEnabled
        self.selectedAccessRight = selectedAccessRight
        self.link = link
        self.isLoading = isLoading
        self.room = room
    }

    func fetchData() {}
}
