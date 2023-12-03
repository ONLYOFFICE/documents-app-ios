//
//  ASCDocSpaceLinkLifeTimeView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 28.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct ASCDocSpaceLinkLifeTimeView: View {
    @ObservedObject private var viewModel = ASCDocSpaceLinkLifeTimeViewModel()

    var body: some View {
        list
            .navigationBarTitle(Text(NSLocalizedString("Link life time", comment: "")), displayMode: .inline)
    }

    private var list: some View {
        List($viewModel.linkLifeTimeModels) { model in
            LinkLifeOptionsCell(model: model) { item in
                viewModel.select(linkLifeTimeModel: item)
            }
        }
    }
}

struct LinkLifeOptionsCell: View {
    @Binding var model: LinkLifeTimeModel
    var tapAction: (LinkLifeTimeModel) -> Void

    var body: some View {
        HStack {
            Text(model.option.localized)
            Spacer()
            if model.selected {
                Image(systemName: "checkmark")
                    .foregroundColor(Asset.Colors.brend.swiftUIColor)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            tapAction(model)
        }
    }
}

struct ASCDocSpaceLinkLifeTimeView_Previews: PreviewProvider {
    static var previews: some View {
        ASCDocSpaceLinkLifeTimeView()
    }
}
