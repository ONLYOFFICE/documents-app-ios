//
//  CreateGeneralLinkView.swift
//  Documents-opensource
//
//  Created by Lolita Chernysheva on 20.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct CreateGeneralLinkView: View {
    @ObservedObject var viewModel = CreateGeneralLinkViewModel()

    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text(NSLocalizedString("General links", comment: "Header for general links section")),
                            footer: Text(NSLocalizedString("Provide general access to the document selecting the required permission level.", comment: "Footer text explaining what 'Create and copy' does")))
                    {
                        ASCLabledCellView(viewModel: viewModel, textString: NSLocalizedString("Create and copy", comment: ""))
                    }
                }
            }
            .navigationBarTitle(Text(NSLocalizedString("Sharing settings", comment: "")), displayMode: .inline)
            .navigationBarItems(leading: Button(action: {
                // MARK: - TODO add close btn action
            }, label: {
                Text(NSLocalizedString("Close", comment: ""))
                    .foregroundColor(Asset.Colors.brend.swiftUIColor)
            }))
        }
    }
}

struct CreateGeneralLinkView_Previews: PreviewProvider {
    static var previews: some View {
        CreateGeneralLinkView()
    }
}
