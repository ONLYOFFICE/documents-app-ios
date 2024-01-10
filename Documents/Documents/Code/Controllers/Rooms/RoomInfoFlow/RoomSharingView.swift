//
//  RoomSharingView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 19.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Combine
import Kingfisher
import MBProgressHUD
import SwiftUI

struct RoomSharingView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: RoomSharingViewModel

    var body: some View {
        handleHUD()

        return screenView
            .navigationBarTitle(Text(NSLocalizedString("\(viewModel.room.title)", comment: "")), displayMode: .inline)
            .navigateToChangeAccess(selectedUser: $viewModel.selctedUser, viewModel: viewModel)
            .navigateToEditLink(selectedLink: $viewModel.selectdLink, viewModel: viewModel)
            .navigateToCreateLink(isDisplaing: $viewModel.isCreatingLinkScreenDisplaing, viewModel: viewModel)
            .onAppear { viewModel.onAppear() }
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
                ASCCreateLinkCellView(
                    model: .init(
                        textString: NSLocalizedString("Create and copy", comment: ""),
                        imageNames: [],
                        onTapAction: viewModel.createAndCopyGeneralLink
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
                    ASCCreateLinkCellView(
                        model: ASCCreateLinkCellModel(
                            textString: NSLocalizedString("Create and copy", comment: ""),
                            imageNames: [],
                            onTapAction: viewModel.createAndCopyAdditionalLink
                        )
                    )
                } else {
                    ForEach(viewModel.additionalLinkModels) { linkModel in
                        RoomSharingLinkRow(model: linkModel)
                    }
                    .onDelete { indexSet in
                        viewModel.deleteAdditionalLink(indexSet: indexSet)
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

    private func handleHUD() {
        if viewModel.isActivitiIndicatorDisplaying {
            MBProgressHUD.currentHUD?.hide(animated: false)
            let hud = MBProgressHUD.showTopMost()
            hud?.mode = .indeterminate
        } else {
            if let hud = MBProgressHUD.currentHUD {
                if let resultModalModel = viewModel.resultModalModel {
                    switch resultModalModel.result {
                    case .success:
                        hud.setState(result: .success(resultModalModel.message))
                    case .failure:
                        hud.setState(result: .failure(resultModalModel.message))
                    }

                    hud.hide(animated: true, afterDelay: resultModalModel.hideAfter)
                } else {
                    hud.hide(animated: true)
                }
            }
        }
    }
}

private extension View {
    func navigateToChangeAccess(
        selectedUser: Binding<ASCUser?>,
        viewModel: RoomSharingViewModel
    ) -> some View {
        navigation(item: selectedUser) { user in
            RoomSharingAccessTypeView(
                viewModel: RoomSharingAccessTypeViewModel(
                    room: viewModel.room,
                    user: user
                )
            )
        }
    }

    func navigateToCreateLink(
        isDisplaing: Binding<Bool>,
        viewModel: RoomSharingViewModel
    ) -> some View {
        navigation(isActive: isDisplaing) {
            RoomSharingCustomizeLinkView(viewModel: RoomSharingCustomizeLinkViewModel(
                room: viewModel.room,
                outputLink: viewModel.changedLinkBinding
            ))
        }
    }

    func navigateToEditLink(
        selectedLink: Binding<RoomSharingLinkModel?>,
        viewModel: RoomSharingViewModel
    ) -> some View {
        navigation(item: selectedLink, destination: { link in
            RoomSharingCustomizeLinkView(viewModel: RoomSharingCustomizeLinkViewModel(
                room: viewModel.room,
                inputLink: link,
                outputLink: viewModel.changedLinkBinding
            ))
        })
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
    var image: ImageSourceType
    var title: String
    var subtitle: String
    var isOwner: Bool
    var onTapAction: () -> Void

    enum ImageSourceType {
        case url(String)
        case asset(ImageAsset)
    }
}

struct ASCUserRow: View {
    var model: ASCUserRowModel

    var body: some View {
        HStack {
            imageView(for: model.image)
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
    
    @ViewBuilder
    private func imageView(for imageType: ASCUserRowModel.ImageSourceType) -> some View {
        switch imageType {
        case let .url(string):
            if let portal = OnlyofficeApiClient.shared.baseURL?.absoluteString.trimmed,
               !string.contains("/default_user_photo_size_"),
            let url = URL(string: (portal + string)) {
                KFImageView(url: url)
                    .frame(width: 40, height: 40)
                    .cornerRadius(20)
                    .clipped()
            } else {
                Image(asset: Asset.Images.avatarDefault)
                    .resizable()
                    .frame(width: 40, height: 40)
            }
        case let .asset(asset):
            Image(asset: asset)
                .resizable()
                .frame(width: 40, height: 40)
        }
    }
}


struct KFImageView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.kf.setImage(with: url)
        uiView.contentMode = .scaleAspectFit
    }
}
