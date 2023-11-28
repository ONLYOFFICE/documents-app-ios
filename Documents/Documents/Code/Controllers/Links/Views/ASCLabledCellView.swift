//
//  ASCLabledCellView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 27.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

enum CellType {
    case deletable, standard
}

enum TextAlignment {
    case center, leading, trailing
}

struct ASCLabledCellView: View {
    var textString: String
    var cellType: CellType
    var textAlignment: TextAlignment

    var body: some View {
//        HStack {
//            Spacer()
//            Text(textString)
//                .foregroundColor(Asset.Colors.brend.swiftUIColor)
//            Spacer()
//        }
        HStack {
            if textAlignment == .trailing || textAlignment == .center {
                Spacer()
            }

            Text(textString)
                .foregroundColor(cellType == .deletable ? Color.red : Asset.Colors.brend.swiftUIColor)

            if textAlignment == .leading || textAlignment == .center {
                Spacer()
            }
        }
    }
}
