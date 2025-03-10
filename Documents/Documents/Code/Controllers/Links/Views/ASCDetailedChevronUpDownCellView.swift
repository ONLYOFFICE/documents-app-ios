//
//  ASCDetailedChevronUpDownCellView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 05.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Combine
import SwiftUI

struct ASCDetailedChevronUpDownCellViewModel {
    let title: String
    let detail: String
    let isEnabled: Bool
}

struct ASCDetailedChevronUpDownCellView: View {
    var model: ASCDetailedChevronUpDownCellViewModel

    var body: some View {
        HStack {
            Text(verbatim: model.title)
                .foregroundColor(model.isEnabled ? .label : .secondaryLabel)
            Spacer()
            HStack {
                Text(verbatim: model.detail)
                    .foregroundColor(.secondaryLabel)
                ChevronUpDownView()
            }
        }
    }
}
