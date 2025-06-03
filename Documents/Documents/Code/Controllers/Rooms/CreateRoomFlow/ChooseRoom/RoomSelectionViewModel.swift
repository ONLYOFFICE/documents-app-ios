//
//  RoomSelectionViewModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 17.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

class RoomSelectionViewModel: ObservableObject {
    
    @Published var selectedType: RoomTypeModel?
    
    var isCreateTemplateEnabled: Bool
    
    init(isCreateTemplateEnabled: Bool = false) {
        self.isCreateTemplateEnabled = isCreateTemplateEnabled
    }
    
    func roomTypeModel(showDisclosureIndicator: Bool) -> [RoomTypeRowModel] {
        var models = CreatingRoomType.allCases.map { type in
            let typeModel = type.toRoomTypeModel(showDisclosureIndicator: showDisclosureIndicator)
            return typeModel.mapToRowModel { [weak self] in
                self?.selectedType = typeModel
            }
        }
        if isCreateTemplateEnabled {
            models.append(
                RoomTypeRowModel(
                    name: "From template",
                    description: NSLocalizedString("Create a room based on a template. All settings, users, folders and files will be taken from the selected room template.", comment: ""),
                    icon: Asset.Images.listRoomTemplate.image,
                    showDisclosureIndicator: true
                )  { [weak self] in
// TODO: - show template
                }
            )
        }
        return models
    }
}

// MARK: - CreatingRoomType extension

extension CreatingRoomType {
    func toRoomTypeModel(showDisclosureIndicator: Bool) -> RoomTypeModel {
        return RoomTypeModel(type: self, name: name, description: description, icon: icon, showDisclosureIndicator: showDisclosureIndicator)
    }
}
