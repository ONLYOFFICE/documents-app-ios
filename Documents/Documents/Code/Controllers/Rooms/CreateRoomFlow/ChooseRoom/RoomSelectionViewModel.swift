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

    var onShowTemplates: (() -> Void)?

    init(
        isCreateTemplateEnabled: Bool = false,
        onShowTemplates: (() -> Void)? = nil
    ) {
        self.isCreateTemplateEnabled = isCreateTemplateEnabled
        self.onShowTemplates = onShowTemplates
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
                ) { [weak self] in
                    self?.onShowTemplates?()
                }
            )
        }
        return models
    }
}

// MARK: - CreatingRoomType extension

extension CreatingRoomType {
    func toRoomTypeModel(showDisclosureIndicator: Bool) -> RoomTypeModel {
        return RoomTypeModel(type: self, name: name, description: description, icon: icon(isTemplate: false), showDisclosureIndicator: showDisclosureIndicator)
    }
}
