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
    var subtitle: String? = nil
    var image: Image? = nil
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
                if let image = model.image {
                    image
                        .renderingMode(.template)
                        .foregroundColor(.secondaryLabel)
                } else if let subtitle = model.subtitle {
                    Text(verbatim: subtitle)
                        .foregroundColor(.secondaryLabel)
                }
                ChevronUpDownView()
            }
        }
    }
}
