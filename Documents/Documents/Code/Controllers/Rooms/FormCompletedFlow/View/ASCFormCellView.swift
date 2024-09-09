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
    
    static var empty = ASCFormCellModel(title: "", author: "", date: "")
}

struct ASCFormCellView: View {
    
    var model: ASCFormCellModel
    
    var body: some View {
        HStack(spacing: 15) {
            Asset.Images.listFormatPdf.swiftUIImage
            VStack(alignment: .leading, spacing: 3) {
                Text(model.title)
                    .font(.footnote)
                    .foregroundColor(.primary)
                Text(model.author)
                    .font(.caption2)
                    .foregroundColor(.secondaryLabel)
                Text(model.date)
                    .font(.caption2)
                    .foregroundColor(.secondaryLabel)
            }
            Spacer()
            
            Image(systemName: "link")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundColor(Asset.Colors.brend.swiftUIColor)
        }
    }
}

struct ASCFormCellView_Previews: PreviewProvider {
    static var previews: some View {
        ASCFormCellView(model: ASCFormCellModel(title: "1 - Terry Dorwart - 2021", author: "Terry Dorwart", date: "04.06.2021"))
    }
}
