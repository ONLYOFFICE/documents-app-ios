//
//  PasswordCellView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 08.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Combine
import SwiftUI

struct PasswordCellModel {
    var password: String
    var isPasswordVisible: Bool
}

struct PasswordCellView: View {
    @State var model: PasswordCellModel

    var body: some View {
        HStack {
            if model.isPasswordVisible {
                TextField(NSLocalizedString("Password", comment: ""), text: $model.password)
                    .textFieldStyle(.automatic)
            } else {
                SecureField(NSLocalizedString("Password", comment: ""), text: $model.password)
                    .textFieldStyle(.automatic)
            }

            Button(action: {
                model.isPasswordVisible.toggle()
            }) {
                Image(systemName: model.isPasswordVisible ? "eye.slash" : "eye")
                    .foregroundColor(Asset.Colors.brend.swiftUIColor)
            }
        }
        .padding()
    }
}
