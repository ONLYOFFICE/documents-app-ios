//
//  CheckmarkCellView.swift
//  Documents-opensource
//
//  Created by Lolita Chernysheva on 06.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI
import Combine

struct CheckmarkCellViewModel {
    var text: String
    var isChecked: Bool
}

struct CheckmarkCellView: View {
    @State var model: CheckmarkCellViewModel

    var body: some View {
        HStack {
            Text(model.text)
                .font(.body)
                .foregroundColor(.primary)
            Spacer()
            if model.isChecked {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
}
