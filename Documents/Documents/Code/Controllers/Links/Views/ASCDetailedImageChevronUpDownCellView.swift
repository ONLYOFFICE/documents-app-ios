//
//  ASCDetailedImageChevronUpDownCellView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 25.12.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Combine
import SwiftUI

struct ASCDetailedImageChevronUpDownCellViewModel {
    let title: String
    let image: Image
    let isEnabled: Bool
}

struct ASCDetailedImageChevronUpDownCellView: View {
    var model: ASCDetailedImageChevronUpDownCellViewModel

    var body: some View {
        HStack {
            Text(verbatim: model.title)
                .foregroundColor(model.isEnabled ? .label : .secondaryLabel)
            Spacer()
            HStack {
                model.image
                    .renderingMode(.template)
                    .foregroundColor(.secondaryLabel)
                ChevronUpDownView()
            }
        }
    }
}
