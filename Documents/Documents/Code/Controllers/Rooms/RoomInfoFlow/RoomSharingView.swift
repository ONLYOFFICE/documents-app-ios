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
            RoomSharingLinkRow(model: viewModel.generalLinkModel)
        }
    }
    
    private var additionalLinksSection: some View {
        Section(header: Text(NSLocalizedString("Additional links", comment: ""))) {
            if viewModel.additionalLinkModels.isEmpty {
                ASCCreateLinkCellView(model: ASCCreateLinkCellModel(textString: NSLocalizedString("Create and copy", comment: ""), imageNames: [], onTapAction: {
                    viewModel.createAddLinkAction()
                }))
            } else {
                ForEach(viewModel.additionalLinkModels) { linkModel in
                    RoomSharingLinkRow(model: linkModel)
                }
            }
        }
    }

    private var adminSection: some View {
        Section(header: Text(NSLocalizedString("Administration", comment: ""))) {
            ForEach(viewModel.admins) { model in
                ASCUserRow(
                    model: model
                )
            }
        }
    }

    private var usersSection: some View {
        Section(header: Text(NSLocalizedString("Users", comment: ""))) {
            ForEach(viewModel.users) { model in
                ASCUserRow(model: model
                )
            }
        }
    }
}

//struct RoomSharingView_Previews: PreviewProvider {
//    static var previews: some View {
//        RoomSharingView(
//            viewModel: RoomSharingViewModel(room: .init())
//
//        )
//    }
//}

struct ASCUserRowModel: Identifiable {
    var id = UUID()
    var image: String
    var title: String
    var subtitle: String
    var isOwner: Bool
}

struct ASCUserRow: View {
    var model: ASCUserRowModel
    
    var body: some View {
        HStack {
            Image(asset: Asset.Images.avatarDefault)//(model.image)
                .resizable()
                .frame(width: 40, height: 40)
            Text(NSLocalizedString("\(model.title)", comment: ""))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Spacer()
            Text(NSLocalizedString("\(model.subtitle)", comment: ""))
                .lineLimit(1)
                .foregroundColor(.secondaryLabel)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.trailing)
            if !model.isOwner {
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(Color.separator)
                    .flipsForRightToLeftLayoutDirection(true)
            }
        }
    }
}

