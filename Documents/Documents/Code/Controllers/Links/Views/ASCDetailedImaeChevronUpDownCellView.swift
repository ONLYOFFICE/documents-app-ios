//
//  ASCDetailedImaeChevronUpDownCellView.swift
//  Documents-opensource
//
//  Created by Lolita Chernysheva on 25.12.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Combine
import SwiftUI

struct ASCDetailedImaeChevronUpDownCellViewModel {
    let title: String
    let image: Image
    let isEnabled: Bool
}

struct ASCDetailedImaeChevronUpDownCellView: View {
    var model: ASCDetailedImaeChevronUpDownCellViewModel

    var body: some View {
        HStack {
            Text(model.title)
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
