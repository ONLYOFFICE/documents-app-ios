//
//  CheckmarkCellView.swift
//  Documents-opensource
//
//  Created by Lolita Chernysheva on 06.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Combine
import SwiftUI

struct CheckmarkCellViewModel {
    var text: String
    var isChecked: Bool

    var onTapAction: () -> Void
}

struct CheckmarkCellView: View {
    var model: CheckmarkCellViewModel

    var body: some View {
        HStack {
            Text(model.text)
            Spacer()
            if model.isChecked {
                Image(systemName: "checkmark")
                    .foregroundColor(Asset.Colors.brend.swiftUIColor)
            }
        }
        .onTapGesture {
            model.onTapAction()
        }
    }
}
