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
            .navigation(item: $viewModel.selectdLink, destination: { link in
                RoomSharingCustomizeLinkView(viewModel: RoomSharingCustomizeLinkViewModel(
                    room: viewModel.room,
                    inputLink: link,
                    outputLink: viewModel.changedLinkBinding
                ))
            })
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
            } else {
                ASCCreateLinkCellView(model: .init(
                    textString: NSLocalizedString("Create and copy", comment: ""),
                    imageNames: [],
                    onTapAction: { viewModel.createGeneralLink() }
                )
                )
            }
        }
    }

    @ViewBuilder
    private var additionalLinksSection: some View {
        if viewModel.generalLinkModel != nil {
            Section(header: additionLinksSectionHeader) {
                if viewModel.additionalLinkModels.isEmpty {
                    ASCCreateLinkCellView(model: ASCCreateLinkCellModel(textString: NSLocalizedString("Create and copy", comment: ""), imageNames: [], onTapAction: {
                        viewModel.createAddLinkAction()
                    }))
                } else {
                    ForEach(viewModel.additionalLinkModels) { linkModel in
                        RoomSharingLinkRow(model: linkModel)
                    }
                    .onDelete { indexSet in
                        viewModel.additionalLinkModels.remove(atOffsets: indexSet)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var adminSection: some View {
        if !viewModel.admins.isEmpty {
            Section(header: usersSectionHeader(title: NSLocalizedString("Administration", comment: ""), count: viewModel.admins.count)) {
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
            Section(header: usersSectionHeader(title: NSLocalizedString("Users", comment: ""), count: viewModel.users.count)) {
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

    private func usersSectionHeader(title: String, count: Int) -> some View {
        HStack {
            Text(title)
            Text("(\(count))")
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
