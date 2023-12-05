//
//  ASCLinkCell.swift
//  Documents
//
//  Created by Lolita Chernysheva on 04.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct ASCLinkCellModel {
    var titleString: String
    var subTitleString: String
    
    var onTapAction: () -> Void
    var onShareAction: () -> Void

    init(titleKey: String,
         subTitleKey: String,
         onTapAction: @escaping () -> Void,
         onShareAction: @escaping () -> Void
    ) {
        self.titleString = NSLocalizedString(titleKey, comment: "")
        self.subTitleString = NSLocalizedString(subTitleKey, comment: "")
        self.onTapAction = onTapAction
        self.onShareAction = onShareAction
    }
}

struct ASCLinkCellView: View {
    @State var model: ASCLinkCellModel
    
    var body: some View {
        HStack {
            Image(uiImage: Asset.Images.navLink.image)
                .background(Color(asset: Asset.Colors.tableCellSelected))
                .cornerRadius(20)
            VStack(alignment: .leading) {
                Text(model.titleString)
                    .font(Font.subheadline)
                //TODO: - add some space
                Text(model.subTitleString)
                    .font(Font.footnote)
                    .foregroundColor(Asset.Colors.textSubtitle.swiftUIColor)
            }

            Spacer()

            HStack {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(Asset.Colors.brend.swiftUIColor)
                    .onTapGesture {
                        model.onShareAction()
                    }

                Image(systemName: "eye.fill") //TODO: - 
                    .foregroundColor(Color.gray)
            }
        }
        .onTapGesture {
            model.onTapAction()
        }
    }
}

