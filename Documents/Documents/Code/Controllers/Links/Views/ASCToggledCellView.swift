//
//  ASCToggledCellView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 08.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Combine
import SwiftUI

struct ASCToggledCellView: View {
    @Binding var model: ASCToggledCellModel

    var body: some View {
        Toggle(
            isOn: $model.isOn)
        {
            Text(NSLocalizedString(model.title, comment: ""))
        }
    }
}

struct ASCToggledCellModel {
    var title: String
    var isOn: Bool
}
