//
//  CreateGeneralLinkView.swift
//  Documents-opensource
//
//  Created by Lolita Chernysheva on 20.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct ASCCreateLinkCellView: View {
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

struct CreateGeneralLinkView: View {
    @ObservedObject var viewModel = CreateGeneralLinkViewModel()
    
    @State var isDocSpaceLinkViewPresenting = false

    var body: some View {
        VStack {
            List {
                Section(header: Text(NSLocalizedString("General links", comment: "Header for general links section")),
                        footer: Text(NSLocalizedString("Provide general access to the document selecting the required permission level.", comment: "Footer text explaining what 'Create and copy' does")))
                {
                    ASCCreateLinkCellView(viewModel: viewModel, textString: NSLocalizedString("Create and copy", comment: ""))
                        .onTapGesture {
                            isDocSpaceLinkViewPresenting = true
                        }
                }
            }
        }
        .navigation(isActive: $isDocSpaceLinkViewPresenting, destination: {
            ASCDocSpaceLinkView()
        })
        .navigationBarTitle(Text(NSLocalizedString("Sharing settings", comment: "")), displayMode: .inline)
        .navigationBarItems(leading: Button(action: {
            // MARK: - TODO add close btn action
        }, label: {
            Text(NSLocalizedString("Close", comment: ""))
                .foregroundColor(Asset.Colors.brend.swiftUIColor)
        }))
    }
}

struct CreateGeneralLinkView_Previews: PreviewProvider {
    static var previews: some View {
        CreateGeneralLinkView()
    }
}
