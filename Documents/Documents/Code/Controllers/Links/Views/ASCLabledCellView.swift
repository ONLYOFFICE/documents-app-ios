//
//  ASCLabledCellView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 27.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct ASCLabledCellView: View {
    @ObservedObject var viewModel = CreateGeneralLinkViewModel()
    var textString: String
    var body: some View {
        Button(action: {
            viewModel.createAndCopyLink()
        }) {
            HStack {
                Text(textString)
                    .foregroundColor(Asset.Colors.brend.swiftUIColor)
                Spacer()
                if let status = viewModel.linkCreationStatus {
                    Text(status)
                        .font(.footnote)
                        .foregroundColor(.gray) // MARK: - TODO color
                }
            }
        }
    }
}
