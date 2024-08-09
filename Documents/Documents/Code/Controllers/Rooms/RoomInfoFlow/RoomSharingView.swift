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
    @ObservedObject var viewModel: RoomSharingViewModel

    var body: some View {
        handleHUD()

        return screenView
            .navigationBarTitle(Text(viewModel.room.title), displayMode: .inline)
            .navigateToChangeAccess(selectedUser: $viewModel.selectedUser, viewModel: viewModel)
            .navigateToEditLink(selectedLink: $viewModel.selectdLink, viewModel: viewModel)
            .navigateToCreateLink(isDisplaing: $viewModel.isCreatingLinkScreenDisplaing, viewModel: viewModel)
            .sharingSheet(isPresented: $viewModel.isSharingScreenPresenting, link: viewModel.sharingLink)
            .navigateToAddUsers(isDisplaying: $viewModel.isAddUsersScreenDisplaying, viewModel: viewModel)
            .navigationBarItems(viewModel: viewModel)
            .alert(isPresented: $viewModel.isRevokeAlertDisplaying, content: revokeAlert)
            .onAppear { viewModel.onAppear() }
    }
    
    @ViewBuilder
    private var screenView: some View {
        if !viewModel.isInitializing {
            VStack {
                roomDescriptionText
                List {
                    sharedLinksSection
                    adminSection
                    usersSection
                    invitesSection
                }
            }
            .background(Color.systemGroupedBackground)
        } else {
            VStack {
                ActivityIndicatorView()
            }
        }
    }
    
    @ViewBuilder
    private var roomDescriptionText: some View {
        if viewModel.room.roomType != .colobaration {
            Text(viewModel.roomTypeDescription)
                .multilineTextAlignment(.center)
                .padding(.top, Constants.descriptionTopPadding)
                .padding(.horizontal, Constants.horizontalAlignment)
                .font(.caption)
                .foregroundColor(.secondaryLabel)
        }
    }

    @ViewBuilder
    private var sharedLinksSection: some View {
        if viewModel.isSharingPossible, viewModel.isPossibleCreateNewLink {
            Section(header: sharedLinksSectionHeader) {
                if viewModel.sharedLinksModels.isEmpty {
                    ASCCreateLinkCellView(
                        model: ASCCreateLinkCellModel(
                            textString: NSLocalizedString("Create and copy", comment: ""),
                            imageNames: [],
                            onTapAction: viewModel.sharedLinksModels.isEmpty
                                ? viewModel.createAndCopyGeneralLink
                                : viewModel.createAndCopyAdditionalLink
                        )
                    )
                } else {
                    ForEach(viewModel.sharedLinksModels) { linkModel in
                        RoomSharingLinkRow(model: linkModel)
                    }
                    .onDelete { indexSet in
                        viewModel.deleteSharedLink(indexSet: indexSet)
                    }
                }
            }
            .alert(isPresented: $viewModel.isDeleteAlertDisplaying, content: deleteAlert)
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

    @ViewBuilder
    private var sharedLinksSectionHeader: some View {
        if viewModel.room.isFillingFormRoom {
            Text(NSLocalizedString("Public link", comment: ""))
        } else {
            HStack {
                Text(NSLocalizedString("Shared links", comment: ""))
                Text("(\(viewModel.sharedLinksModels.count)/\(viewModel.linksLimit))")
                Spacer()
                if viewModel.sharedLinksModels.count < viewModel.linksLimit && viewModel.isSharingPossible {
                    Button {
                        viewModel.createAddLinkAction()
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(Asset.Colors.brend.swiftUIColor)
                    }
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
            MBProgressHUD.showTopMost(mode: .indeterminate)
        } else if let hud = MBProgressHUD.currentHUD {
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

// MARK: - Alerts

private extension RoomSharingView {
    func deleteAlert() -> Alert {
        Alert(
            title: Text(NSLocalizedString("Delete link", comment: "")),
            message: Text(NSLocalizedString("The link will be deleted permanently. You will not be able to undo this action.", comment: "")),
            primaryButton: .destructive(Text(NSLocalizedString("Delete", comment: "")), action: {
                viewModel.proceedDeletingLink()
            }),
            secondaryButton: .cancel {
                viewModel.declineRemoveLink()
            }
        )
    }

    func revokeAlert() -> Alert {
        Alert(
            title: Text(NSLocalizedString("Revoke link", comment: "")),
            message: Text(NSLocalizedString("The previous link will become unavailable. A new shared link will be created.", comment: "")),
            primaryButton: .destructive(Text(NSLocalizedString("Revoke link", comment: "")), action: {
                viewModel.proceedDeletingLink()
            }),
            secondaryButton: .cancel {
                viewModel.declineRemoveLink()
            }
        )
    }
}

private extension View {
    func navigationBarItems(viewModel: RoomSharingViewModel) -> some View {
        navigationBarItems(
            leading: Button(ASCLocalization.Common.close) {
                UIApplication.topViewController()?.dismiss(animated: true)
            },
            trailing: viewModel.isSharingPossible
                ? addUsersButton(viewModel: viewModel)
                : nil
        )
    }

    func addUsersButton(viewModel: RoomSharingViewModel) -> some View {
        Button(action: {
            viewModel.addUsers()
        }) {
            Image(systemName: "person.crop.circle.badge.plus")
        }
    }

    func sharingSheet(isPresented: Binding<Bool>, link: URL?) -> some View {
        sheet(isPresented: isPresented) {
            if let link {
                ActivityView(activityItems: [link])
            }
        }
    }

    func navigateToChangeAccess(
        selectedUser: Binding<ASCUser?>,
        viewModel: RoomSharingViewModel
    ) -> some View {
        navigation(item: selectedUser) { user in
            RoomSharingAccessTypeView(
                viewModel: RoomSharingAccessTypeViewModel(
                    room: viewModel.room,
                    user: user,
                    onRemove: viewModel.onUserRemove(userId:)
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

    func navigateToAddUsers(
        isDisplaying: Binding<Bool>,
        viewModel: RoomSharingViewModel
    ) -> some View {
        navigation(isActive: isDisplaying) {
            InviteUsersView(
                viewModel: InviteUsersViewModel(
                    room: viewModel.room
                )
            )
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
            Text(model.title)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Spacer()

            Text(model.subtitle)
                .lineLimit(1)
                .foregroundColor(.secondaryLabel)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.trailing)

            if !model.isOwner {
                ChevronRightView()
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
               let url = URL(string: portal + string)
            {
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

private struct Constants {
    static let horizontalAlignment: CGFloat = 16
    static let descriptionTopPadding: CGFloat = 20
}
