//
//  SelectableLabledCellView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 05.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct SelectableLabledCellModel {
    var title: String
    var isSelected: Bool
    var onTapAction: () -> Void
}

struct SelectableLabledCellView: View {
    var model: SelectableLabledCellModel

    var body: some View {
        HStack {
            Text(model.title)
            Spacer()
            if model.isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(Asset.Colors.brend.swiftUIColor)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            model.onTapAction()
        }
    }
}
