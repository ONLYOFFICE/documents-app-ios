//
//  RoomSelectionViewModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 17.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

class RoomSelectionViewModel: ObservableObject {
    @Published var roomsTypeModels: [RoomTypeModel] = CreatingRoomType.allCases.map { $0.toRoomTypeModel() }
}

// MARK: - CreatingRoomType extension

extension CreatingRoomType {
    func toRoomTypeModel() -> RoomTypeModel {
        return RoomTypeModel(type: self, name: name, description: description, icon: icon)
    }
}
