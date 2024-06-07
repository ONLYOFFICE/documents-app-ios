//
//  ASCDetailedChevronUpDownCellView.swift
//  Documents-opensource
//
//  Created by Lolita Chernysheva on 05.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Combine
import SwiftUI

struct ASCDetailedChevronUpDownCellViewModel {
    let title: String
    let detail: String
}

struct ASCDetailedChevronUpDownCellView: View {
    var model: ASCDetailedChevronUpDownCellViewModel

    var body: some View {
        HStack {
            Text(model.title)
                .foregroundColor(.black)
            Spacer()
            HStack {
                Text(model.detail)
                    .foregroundColor(.secondaryLabel)
                ChevronUpDownView()
            }
        }
    }
}
