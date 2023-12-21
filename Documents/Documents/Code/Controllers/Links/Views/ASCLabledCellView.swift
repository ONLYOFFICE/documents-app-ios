//
//  ASCLabledCellView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 27.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct ASCLabledCellView: View {
    @State var model: ASCLabledCellModel

    var body: some View {
        Text(model.textString)
            .frame(maxWidth: .infinity, alignment: frameAlignment(for: model.textAlignment))
            .foregroundColor(textColor(for: model.cellType))
            .multilineTextAlignment(convertToTextAlignment(model.textAlignment))
            .onTapGesture {
                model.onTapAction()
            }
    }

    private func textColor(for cellType: CellType) -> Color {
        switch cellType {
        case .deletable:
            return Color.red
        case .standard:
            return Asset.Colors.brend.swiftUIColor
        }
    }

    private func convertToTextAlignment(_ alignment: TextAlignment) -> SwiftUI.TextAlignment {
        switch alignment {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }

    private func frameAlignment(for alignment: TextAlignment) -> Alignment {
        switch alignment {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }
}

struct ASCLabledCellModel {
    var textString: String
    var cellType: CellType
    var textAlignment: TextAlignment
    var onTapAction: () -> Void
}

enum CellType {
    case deletable, standard
}

enum TextAlignment {
    case center, leading, trailing
}
