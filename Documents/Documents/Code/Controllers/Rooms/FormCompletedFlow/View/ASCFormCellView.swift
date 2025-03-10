//
//  ASCFormCellView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 09.09.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct ASCFormCellModel {
    var title: String
    var author: String
    var date: String

    var onLinkAction: () -> Void

    static var empty = ASCFormCellModel(title: "", author: "", date: "", onLinkAction: {})
}

struct ASCFormCellView: View {
    var model: ASCFormCellModel

    var body: some View {
        HStack(spacing: 15) {
            Asset.Images.listFormatPdf.swiftUIImage
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: model.title)
                    .font(.footnote)
                    .foregroundColor(.primary)
                Text(verbatim: model.author)
                    .font(.caption2)
                    .foregroundColor(.secondaryLabel)
                Text(verbatim: model.date)
                    .font(.caption2)
                    .foregroundColor(.secondaryLabel)
            }
            Spacer()

            Image(systemName: "link")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundColor(Asset.Colors.brend.swiftUIColor)
                .onTapGesture {
                    model.onLinkAction()
                }
        }
    }
}
