//
//  RoomSelectionViewModel.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 17.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

class RoomSelectionViewModel: ObservableObject {
    @Published var rooms: [Room] = CreatingRoomType.allCases.map { $0.toRoom() }
}

// MARK: - CreatingRoomType extension

extension CreatingRoomType {
    func toRoom() -> Room {
        return Room(type: self, name: name, description: description, icon: icon)
    }
}
