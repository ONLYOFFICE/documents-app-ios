//
//  SubTitledDetailCellView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 05.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct SubTitledDetailCellModel {
    var title = ""
    var subtitle = ""
    var onTapAction: () -> Void
}

struct SubTitledDetailCellView: View {
    @State var model: SubTitledDetailCellModel

    var body: some View {
        HStack {
            Text(model.title)
            Spacer()
            Text(model.subtitle)
                .foregroundColor(Asset.Colors.textSubtitle.swiftUIColor)
            ChevronRightView()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            model.onTapAction()
        }
    }
}
