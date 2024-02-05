//
//  ASCCreateLinkCellView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 05.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct ASCCreateLinkCellModel {
    var textString: String
    var imageNames: [String]
    var onTapAction: () -> Void
}

struct ASCCreateLinkCellView: View {
    @State var model: ASCCreateLinkCellModel

    var body: some View {
        Button(action: {
            model.onTapAction()
        }) {
            HStack {
                Text(model.textString)
                    .foregroundColor(Asset.Colors.brend.swiftUIColor)
                Spacer()
            }
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
    }
}

struct ASCCreateLinkCellView_Previews: PreviewProvider {
    static var previews: some View {
        ASCCreateLinkCellView(
            model: ASCCreateLinkCellModel(textString: NSLocalizedString("Create and copy", comment: ""), imageNames: [], onTapAction: {})
        )
    }
}
