//
//  ASCDocSpaceLinkView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 27.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct ASCGeneralLinkCell: View {
    var daysToExpire: Int
    var body: some View {
        HStack {
            Image(uiImage: Asset.Images.navLink.image)
                .background(Color(asset: Asset.Colors.tableCellSelected))
                .cornerRadius(20)
            VStack(alignment: .leading) {
                Text(NSLocalizedString("Anyone with the link", comment: ""))
                    .font(Font.subheadline)

                Text(NSLocalizedString("Expires after \(daysToExpire) days", comment: "")) // MARK: - todo localize
            }
            Spacer()
            Image(systemName: "square.and.arrow.up")
                .foregroundColor(Asset.Colors.brend.swiftUIColor)
            Image(systemName: "eye.fill")
                .foregroundColor(Color.gray)
        }
    }
}

struct ASCDocSpaceLinkView: View {
    @State var isDocSpaceExternalLinkViewPresenting = false
    var body: some View {
        List {
            Section(header: Text(NSLocalizedString("General link", comment: "")),
                    footer: Text(NSLocalizedString("Provide general access to the document selecting the required permission level.", comment: "")))
            {
                ASCGeneralLinkCell(daysToExpire: 7) // MARK: - TODO
                    .onTapGesture {
                        isDocSpaceExternalLinkViewPresenting = true
                    }
                    .navigation(isActive: $isDocSpaceExternalLinkViewPresenting) {
                        ASCDocSpaceExternalLinkView()
                    }
            }

            Section(header: Text(NSLocalizedString("Additional links", comment: "")),
                    footer: Text(NSLocalizedString("Create additional links to share the document with different access rights.", comment: "")))
            {
                ASCLabledCellView(textString: NSLocalizedString("Create and copy", comment: ""), cellType: .standard, textAlignment: .leading)
            }
        }
    }
}

struct ASCDocSpaceLinkView_Previews: PreviewProvider {
    static var previews: some View {
        ASCDocSpaceLinkView()
    }
}
