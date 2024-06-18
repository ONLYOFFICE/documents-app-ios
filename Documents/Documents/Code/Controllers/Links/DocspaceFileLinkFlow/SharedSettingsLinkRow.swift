//
//  SharedSettingsLinkRow.swift
//  Documents-opensource
//
//  Created by Lolita Chernysheva on 01.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

enum LinkAccess: String {
    case anyoneWithLink = "Anyone with the link"
    case docspaceUserOnly = "Docspace user only"

    var isInternal: Bool {
        self == .docspaceUserOnly
    }
}

struct SharedSettingsLinkRowModel: Identifiable {
    var id: String
    var linkAccess: LinkAccess
    var expiredTo: String
    var rights: String
    var isExpired: Bool

    var onTapAction: () -> Void

    static var empty: SharedSettingsLinkRowModel = .init(id: "", linkAccess: .anyoneWithLink, expiredTo: "", rights: "", isExpired: false, onTapAction: {})
}

struct SharedSettingsLinkRow: View {
    var model: SharedSettingsLinkRowModel

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "link")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 21, height: 21)
                .foregroundColor(.gray)
                .padding(10)
                .background(Color(asset: Asset.Colors.tableCellSelected))
                .cornerRadius(40)
            VStack(alignment: .leading) {
                Text(model.linkAccess.rawValue)
                Text(model.isExpired ? NSLocalizedString("The link has expired", comment: "") : model.expiredTo)
                    .foregroundColor(model.isExpired ? .red : .secondaryLabel)
                    .font(.system(size: 13))
            }

            Spacer()

            HStack(spacing: 12) {
                Text(model.rights)
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            model.onTapAction()
        }
    }
}
