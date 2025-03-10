//
//  ASCDocSpaceLinkLifeTimeView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 27.03.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct LinkLifeTimeView: View {
    @ObservedObject var viewModel: LinkLifeTimeViewModel

    var body: some View {
        NavigationView {
            List(viewModel.cellModels, id: \.title) { cellModel in
                SelectableLabledCellView(model: cellModel)
            }
            .navigationBarTitle(Text("Link life time"), displayMode: .inline)
            .navigationBarItems(leading: Button(NSLocalizedString("Back", comment: "")) {}
                .foregroundColor(Asset.Colors.brend.swiftUIColor))
        }
    }
}

struct LinkLifeTimeView_Previews: PreviewProvider {
    static var previews: some View {
        LinkLifeTimeView(viewModel: LinkLifeTimeViewModel())
    }
}
