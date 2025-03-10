//
//  ImagedDetailCellView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 05.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct ImagedDetailCellModel {
    var titleString = ""
    var image: UIImage

    var onTapAction: () -> Void
}

struct ImagedDetailCellView: View {
    @State var model: ImagedDetailCellModel

    var body: some View {
        HStack {
            Text(verbatim: model.titleString)
            Spacer()
            Image(uiImage: model.image)
                .foregroundColor(Asset.Colors.grayLight.swiftUIColor)
            ChevronRightView()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            model.onTapAction()
        }
    }
}
