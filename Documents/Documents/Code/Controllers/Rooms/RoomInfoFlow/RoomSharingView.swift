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
        screenView
            .navigationBarTitle(Text(NSLocalizedString("\(viewModel.room.title)", comment: "")), displayMode: .inline)
            .navigation(item: $viewModel.selctedUser) { user in
                RoomSharingAccessTypeView(
                    viewModel: RoomSharingAccessTypeViewModel(
                        room: viewModel.room,
                        user: user
                    )
                )
            }
            .onAppear {
                viewModel.onAppear()
            }
    }

    @ViewBuilder
    private var screenView: some View {
        if !viewModel.isInitializing {
            List {
                generalLincSection
                additionalLinksSection
                adminSection
                usersSection
                invitesSection
            }
        } else {
            VStack {
                ActivityIndicatorView()
            }
        }
    }

    @ViewBuilder
    private var generalLincSection: some View {
        Section(header: Text(NSLocalizedString("General link", comment: ""))) {
            if let model = viewModel.generalLinkModel {
                RoomSharingLinkRow(model: model)
            }  else {
                ASCCreateLinkCellView(model: .init(
                    textString: NSLocalizedString("Create and copy", comment: ""),
                    imageNames: [],
                    onTapAction: { viewModel.createGeneralLink() })
                )
            }
        }
    }
    
    @ViewBuilder
    private var additionalLinksSection: some View {
        if let generalLink = viewModel.generalLinkModel {
            Section(header: additionLinksSectionHeader) {
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
    }

    @ViewBuilder
    private var adminSection: some View {
        if !viewModel.admins.isEmpty {
            Section(header: Text(NSLocalizedString("Administration", comment: ""))) {
                ForEach(viewModel.admins) { model in
                    ASCUserRow(
                        model: model
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var usersSection: some View {
        if !viewModel.users.isEmpty {
            Section(header: Text(NSLocalizedString("Users", comment: ""))) {
                ForEach(viewModel.users) { model in
                    ASCUserRow(model: model)
                }
            }
        }
    }

    @ViewBuilder
    private var invitesSection: some View {
        if !viewModel.invites.isEmpty {
            Section(header: Text(NSLocalizedString("Expect users", comment: ""))) {
                ForEach(viewModel.invites) { model in
                    ASCUserRow(model: model)
                }
            }
        }
    }

    private var additionLinksSectionHeader: some View {
        HStack {
            Text(NSLocalizedString("Additional links", comment: ""))
                .foregroundColor(.primary)
            Text("(\(viewModel.additionalLinkModels.count)/\(viewModel.additionalLinksLimit))")
            Spacer()
            if viewModel.additionalLinkModels.count < viewModel.additionalLinksLimit {
                Button {
                    viewModel.createAddLinkAction()
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(Asset.Colors.brend.swiftUIColor)
                }
            }
        }
    }

    func sectionHeader(_ header: ASCDocSpaceLinkStateModel.SectionHeader) -> some View {
        let hasSubtitle = header.subtitle != nil
        let hasIcon = header.icon != nil
        return HStack {
            switch (hasSubtitle, hasIcon) {
            case (true, true):
                Text(header.title)
                Text(header.subtitle ?? "")
                Spacer()
                Image(uiImage: header.icon ?? UIImage())
                    .foregroundColor(Asset.Colors.brend.swiftUIColor)
            case (true, false):
                Text(header.title)
                Text(header.subtitle ?? "")
            default:
                Text(header.title)
                Spacer()
            }
        }
    }
}

struct RoomSharingView_Previews: PreviewProvider {
    static var previews: some View {
        RoomSharingView(
            viewModel: RoomSharingViewModel(room: .init(), sharingRoomService: RoomSharingNetworkService())
        )
    }
}

struct ASCUserRowModel: Identifiable {
    var id = UUID()
    var image: String
    var title: String
    var subtitle: String
    var isOwner: Bool
    var onTapAction: () -> Void
}

struct ASCUserRow: View {
    var model: ASCUserRowModel

    var body: some View {
        HStack {
            Image(asset: Asset.Images.avatarDefault) // (model.image)
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
        .contentShape(Rectangle())
        .onTapGesture {
            model.onTapAction()
        }
    }
}
