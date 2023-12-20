//
//  RoomSharingView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 19.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct RoomSharingView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: RoomSharingViewModel


    var body: some View {
        List {
            generalLincSection
            additionalLinksSection
            adminSection
            usersSection
        }
        .navigationBarTitle(Text(NSLocalizedString("\(viewModel.room.title)", comment: "")), displayMode: .inline)
        .navigationBarItems(
            leading: Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Text(NSLocalizedString("Close", comment: ""))
                    .foregroundColor(Asset.Colors.brend.swiftUIColor)
            },
            trailing: Button(action: {
            }) {
                Image(systemName: "person.badge.plus")
                    .foregroundColor(Asset.Colors.brend.swiftUIColor)
                    .scaleEffect(x: -1, y: 1)
            }
        )
    }

    private var generalLincSection: some View {
        Section(header: Text(NSLocalizedString("General link", comment: ""))) {
            RoomSharingLinkRow(model: .init(titleKey: "Sharing link", subTitleKey: "", onTapAction: {
                viewModel.onTap()
            }, onShareAction: {
                viewModel.shareButtonAction()
            }))
        }
    }

    private var additionalLinksSection: some View {
        Section(header: Text(NSLocalizedString("Additional links", comment: ""))) {
            ASCCreateLinkCellView(model: ASCCreateLinkCellModel(textString: "Create and copy", onTapAction: {
                viewModel.createAddLinkAction()
            }))
        }
    }

    private var adminSection: some View {
        Section(header: Text(NSLocalizedString("Administration", comment: ""))) {
            ForEach(viewModel.admins, id: \.userId) { user in
                ASCUserRow(
                    model: ASCUserRowModel(
                        image: user.avatar ?? "",
                        title: user.displayName ?? "",
                        subtitle: user.accessValue.title(),
                        isOwner: user.isOwner)
                )
            }
        }
    }

    private var usersSection: some View {
        Section(header: Text(NSLocalizedString("Users", comment: ""))) {
            ForEach(viewModel.users, id: \.userId) { user in
                ASCUserRow(
                    model: ASCUserRowModel(
                        image: user.avatar ?? "",
                        title: user.displayName ?? "",
                        subtitle: user.accessValue.title(),
                        isOwner: user.isOwner)
                )
            }
        }
    }
}

struct RoomSharingView_Previews: PreviewProvider {
    static var previews: some View {
        RoomSharingView(
            viewModel: RoomSharingViewModel(room: .init())
            
        )
    }
}

struct ASCUserRowModel {
    var image: String
    var title: String
    var subtitle: String
    var isOwner: Bool
}

struct ASCUserRow: View {
    var model: ASCUserRowModel
    
    var body: some View {
        HStack {
            Image(model.image)
            Text(NSLocalizedString("\(model.title)", comment: ""))
            Text(NSLocalizedString("\(model.subtitle)", comment: ""))
            if !model.isOwner {
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(Color.separator)
                    .flipsForRightToLeftLayoutDirection(true)
            }
        }
    }
}

