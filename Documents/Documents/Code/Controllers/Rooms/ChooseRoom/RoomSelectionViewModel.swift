//
//  RoomSelectionViewModel.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 17.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

class RoomSelectionViewModel: ObservableObject {
    @Published var rooms: [Room] = []

    init(rooms: [Room] = []) {
        self.rooms = rooms
    }

    func selectRoom(_ room: Room) {}
}
