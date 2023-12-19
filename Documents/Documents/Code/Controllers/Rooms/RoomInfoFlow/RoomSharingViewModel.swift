//
//  RoomSharingViewModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 19.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

// needed info for presentation:
// 1. public or custom
// 2. does general link exist
// 3. additional links count

final class RoomSharingViewModel: ObservableObject {
    // MARK: - Published vars

    @Published var roomName: String?
    @Published var roomType: String?
    @Published var additionalLinks: [ASCLink]
    @Published var users: [ASCUser]
    @Published var admins: [ASCUser]

    // MARK: - Public vars

    // var room: ASCFolder?

    // MARK: - Private var

    // MARK: - Init

    init(
        roomName: String?,
        roomType: String?,
        additionalLinks: [ASCLink],
        users: [ASCUser],
        admins: [ASCUser]
        // room: ASCFolder?
    ) {
        self.roomName = roomName
        self.roomType = roomType
        self.additionalLinks = additionalLinks
        self.users = users
        self.admins = admins
        // self.room = room
    }
}
