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
        NavigationView {
            list
                .navigationBarTitle(Text(NSLocalizedString("Link life time", comment: "")), displayMode: .inline)
                .navigationBarItems(leading: Button(action: {
                    // MARK: TODO add back btn action
                }, label: {
                    backButtom
                }))
        }
    }

    private var list: some View {
        List($viewModel.linkLifeTimeModels) { model in
            LinkLifeOptionsCell(model: model) { item in
                viewModel.select(linkLifeTimeModel: item)
            }
        }
    }

    private var backButtom: some View {
        HStack {
            Image(systemName: "chevron.left")
                .foregroundColor(Asset.Colors.brend.swiftUIColor)
            Text(NSLocalizedString("Back", comment: ""))
                .foregroundColor(Asset.Colors.brend.swiftUIColor)
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
