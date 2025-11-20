//
//  SharingInfoView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 19.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Combine
import Kingfisher
import MBProgressHUD
import SwiftUI

struct SharingInfoView: View {
    @ObservedObject var viewModel: SharingInfoViewModel

    var body: some View {
        handleHUD()

        return screenView
            .navigateToEditLink(selectedLink: $viewModel.selectdLink, viewModel: viewModel)
            .sharingSheet(isPresented: $viewModel.isSharingScreenPresenting, link: viewModel.sharingLink)
            .navigateToAddUsers(isDisplaying: $viewModel.isAddUsersScreenDisplaying, viewModel: viewModel)
            .toolbar {
                navBarTitle
            }
            .navigationBarItems(viewModel: viewModel)
            .alert(isPresented: $viewModel.isRevokeAlertDisplaying, content: revokeAlert)
            .onAppear { viewModel.onAppear() }
    }

    private var navBarTitle: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack {
                Text(verbatim: viewModel.title)
                Text(verbatim: viewModel.navbarSubtitle)
                    .font(.footnote)
                    .foregroundColor(.secondaryLabel)
            }
        }
    }

    @ViewBuilder
    private var screenView: some View {
        if !viewModel.isInitializing {
            List {
                descriptionText
                sharedLinksSection
                adminSection
                usersSection
                guestsSection
                invitesSection
            }
            .background(Color.systemGroupedBackground.ignoresSafeArea())
        } else {
            VStack {
                ActivityIndicatorView()
            }
        }
    }

    @ViewBuilder
    private var descriptionText: some View {
        if let description = viewModel.entityDescription {
            Text(verbatim: description)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Constants.horizontalAlignment)
                .font(.caption)
                .foregroundColor(.secondaryLabel)
                .listRowBackground(Color.clear)
        }
    }

    @ViewBuilder
    private var sharedLinksSection: some View {
        if viewModel.isSharingPossible, viewModel.isPossibleCreateNewLink {
            Section(header: sharedLinksSectionHeader) {
                if !viewModel.sharedLinksModels.isEmpty {
                    linkRows
                } else {
                    createLink
                }
            }
            .alert(isPresented: $viewModel.isDeleteAlertDisplaying, content: deleteAlert)
        }
    }
    
    private var createLink: some View {
        ASCCreateLinkCellView(
            model: ASCCreateLinkCellModel(
                textString: NSLocalizedString("Create and copy", comment: ""),
                imageNames: [],
                onTapAction: {
                    Task { @MainActor in
                        await viewModel.sharedLinksModels.isEmpty
                            ? viewModel.createAndCopyGeneralLink()
                            : viewModel.createAndCopyAdditionalLink()
                    }
                }
            )
        )
    }
    
    @ViewBuilder
    private var linkRows: some View {
        if #available(iOS 15.0, *) {
            ForEach(Array(viewModel.sharedLinksModels.enumerated()), id: \.element.id) { index, linkModel in
                RoomSharingLinkRow(model: linkModel)
                    .swipeActions {
                        Button(role: .destructive) {
                            viewModel.deleteSharedLink(indexSet: [index])
                        } label: {
                            if linkModel.isGeneral, !viewModel.canRemoveGeneralLink {
                                Text("Revoke")
                            } else {
                                Text("Remove")
                            }
                        }
                    }
            }
        } else {
            ForEach(viewModel.sharedLinksModels) { linkModel in
                RoomSharingLinkRow(model: linkModel)
            }
            .onDelete { indexSet in
                viewModel.deleteSharedLink(indexSet: indexSet)
            }
        }
    }

    @ViewBuilder
    private var adminSection: some View {
        if !viewModel.admins.isEmpty {
            Section(header: usersSectionHeader(title: NSLocalizedString("Administration", comment: ""), count: viewModel.admins.count)) {
                ForEach(viewModel.admins) { model in
                    makeUserRow(for: model)
                }
            }
        }
    }

    @ViewBuilder
    private var usersSection: some View {
        if !viewModel.users.isEmpty {
            Section(header: usersSectionHeader(title: NSLocalizedString("Users", comment: ""), count: viewModel.users.count)) {
                ForEach(viewModel.users) { model in
                    makeUserRow(for: model)
                }
            }
        }
    }

    @ViewBuilder
    private var guestsSection: some View {
        if !viewModel.guests.isEmpty {
            Section(
                header: usersSectionHeader(
                    title: NSLocalizedString("Guests", comment: ""),
                    count: viewModel.guests.count
                )
            ) {
                ForEach(viewModel.guests) { model in
                    makeUserRow(for: model)
                }
            }
        }
    }

    @ViewBuilder
    private var invitesSection: some View {
        if !viewModel.invites.isEmpty {
            Section(
                header: usersSectionHeader(
                    title: NSLocalizedString("Expect users", comment: ""),
                    count: viewModel.invites.count
                )
            ) {
                ForEach(viewModel.invites) { model in
                    makeUserRow(for: model)
                }
            }
        }
    }

    @ViewBuilder
    private func makeUserRow(for model: ASCUserRowModel) -> some View {
        if viewModel.isUserSelectionAllow, !model.isOwner {
            MenuView(menuItems: viewModel.buildAccessMenu(for: model)) {
                ASCUserRow(model: model)
            }
        } else {
            ASCUserRow(model: model)
        }
    }

    @ViewBuilder
    private var sharedLinksSectionHeader: some View {
        if viewModel.isAddingLinksAvailable {
            sharedLinksHeader
        } else {
            formRoomHeader
        }
    }

    private var formRoomHeader: some View {
        Text("Public link")
    }

    private var sharedLinksHeader: some View {
        HStack {
            Text(verbatim: sharedLinksTitle)
            Spacer()
            if viewModel.canAddOneMoreLink {
                addButton
            }
        }
    }

    private var sharedLinksTitle: String {
        let title = NSLocalizedString("Shared links", comment: "")
        return "\(title) (\(viewModel.sharedLinksModels.count)/\(viewModel.linksLimit))"
    }

    private var addButton: some View {
        Button {
            Task { @MainActor in
                await viewModel.sharedLinksModels.isEmpty
                    ? viewModel.createAndCopyGeneralLink()
                    : viewModel.createAndCopyAdditionalLink()
            }

        } label: {
            Image(systemName: "plus")
                .foregroundColor(Asset.Colors.brend.swiftUIColor)
        }
    }

    private func usersSectionHeader(title: String, count: Int) -> some View {
        HStack {
            Text(verbatim: title)
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

private extension SharingInfoView {
    func deleteAlert() -> Alert {
        Alert(
            title: Text("Delete link"),
            message: Text("The link will be deleted permanently. You will not be able to undo this action."),
            primaryButton: .destructive(Text("Delete"), action: {
                Task { @MainActor in
                    await viewModel.proceedDeletingLink()
                }
            }),
            secondaryButton: .cancel {
                viewModel.declineRemoveLink()
            }
        )
    }

    func revokeAlert() -> Alert {
        Alert(
            title: Text("Revoke link"),
            message: Text("The previous link will become unavailable. A new shared link will be created."),
            primaryButton: .destructive(Text("Revoke link"), action: {
                Task { @MainActor in
                    await viewModel.proceedDeletingLink()
                }
            }),
            secondaryButton: .cancel {
                viewModel.declineRemoveLink()
            }
        )
    }
}

private extension View {
    func navigationBarItems(viewModel: SharingInfoViewModel) -> some View {
        navigationBarItems(
            leading: Button(ASCLocalization.Common.close) {
                UIApplication.topViewController()?.dismiss(animated: true)
            },
            trailing: viewModel.isSharingPossible
                ? addUsersButton(viewModel: viewModel)
                : nil
        )
    }

    func addUsersButton(viewModel: SharingInfoViewModel) -> some View {
        Button(action: {
            viewModel.addUsers()
        }) {
            Image(systemName: "person.crop.circle.badge.plus")
        }
    }

    func navigateToEditLink(
        selectedLink: Binding<SharingInfoLinkModel?>,
        viewModel: SharingInfoViewModel
    ) -> some View {
        switch viewModel.entityType {
        case let .room(room):
            navigation(item: selectedLink, destination: { link in
                EditSharedLinkView(viewModel: EditSharedLinkViewModel(
                    entity: .room(room),
                    inputLink: link,
                    outputLink: viewModel.changedLinkBinding
                ))
            })
        case let .file(file):
            navigation(item: selectedLink, destination: { link in
                EditSharedLinkView(viewModel: EditSharedLinkViewModel(
                    entity: .file(file),
                    inputLink: link,
                    outputLink: viewModel.changedLinkBinding
                ))
            })
        case let .folder(folder):
            navigation(item: selectedLink, destination: { link in
                EditSharedLinkView(viewModel: EditSharedLinkViewModel(
                    entity: .folder(folder),
                    inputLink: link,
                    outputLink: viewModel.changedLinkBinding
                ))
            })
        }
    }

    func navigateToAddUsers(
        isDisplaying: Binding<Bool>,
        viewModel: SharingInfoViewModel
    ) -> some View {
        modifier(NavigateToAddUsersModifier(isDisplaying: isDisplaying, viewModel: viewModel))
    }
}

private struct NavigateToAddUsersModifier: ViewModifier {
    @Binding var isDisplaying: Bool
    let viewModel: SharingInfoViewModel

    func body(content: Content) -> some View {
        switch viewModel.entityType {
        case let .room(room):
            content.navigation(isActive: $isDisplaying) {
                InviteUsersView(
                    viewModel: InviteUsersViewModel(room: room)
                )
                .onDisappear {
                    Task { @MainActor in
                        try? await viewModel.updateData()
                    }
                }
            }
            
        case let .file(file):
            sheet(content: content, entity: file)
            
        case let .folder(folder):
            sheet(content: content, entity: folder)
        }
    }
    
    @ViewBuilder
    private func sheet(content: Content, entity: ASCEntity) -> some View {
        content.sheet(isPresented: $isDisplaying) {
            SharingInviteRightHoldersRepresentable(entity: entity)
                .ignoresSafeArea(edges: .bottom)
                .onDisappear {
                    Task { @MainActor in
                        try? await viewModel.updateData()
                    }
                }
        }
    }
}

struct ASCUserRowModel: Identifiable {
    var id: String
    var image: ImageSourceType
    var userName: String
    var access: ASCShareAccess
    var accessString: String
    var emailString: String
    var isOwner: Bool
    var showRightIcon: Bool

    enum ImageSourceType {
        case url(String)
        case asset(ImageAsset)
    }
}

struct ASCUserRow: View {
    var model: ASCUserRowModel

    var subtitle: String {
        [model.accessString, model.emailString]
            .compactMap { $0.isEmpty ? nil : $0 }
            .joined(separator: " | ")
    }

    var body: some View {
        HStack(alignment: .center) {
            imageView(for: model.image)

            VStack(alignment: .leading) {
                Text(verbatim: model.userName)
                    .lineLimit(1)
                    .font(.callout)
                Text(verbatim: subtitle)
                    .lineLimit(1)
                    .foregroundColor(.secondaryLabel)
                    .font(.caption)
            }

            Spacer()

            Text(verbatim: model.accessString)
                .lineLimit(1)
                .foregroundColor(.secondaryLabel)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.trailing)

            if model.showRightIcon {
                ChevronUpDownView()
            }
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func imageView(for imageType: ASCUserRowModel.ImageSourceType) -> some View {
        switch imageType {
        case let .url(string):
            if let portal = OnlyofficeApiClient.shared.baseURL?.absoluteString.trimmed,
               !string.contains(String.defaultUserPhotoSize),
               let url = URL(string: portal)?.appendingSafePath(string)
            {
                KFOnlyOfficeProviderImageView(url: url)
                    .resizable()
                    .frame(width: Constants.imageWidth, height: Constants.imageHeight)
                    .cornerRadius(Constants.imageCornerRadius)
                    .clipped()
            } else {
                Image(asset: Asset.Images.avatarDefault)
                    .resizable()
                    .frame(width: Constants.imageWidth, height: Constants.imageHeight)
            }
        case let .asset(asset):
            Image(asset: asset)
                .resizable()
                .frame(width: Constants.imageWidth, height: Constants.imageHeight)
        }
    }
}

private enum Constants {
    static let horizontalAlignment: CGFloat = 16
    static let descriptionTopPadding: CGFloat = 20
    static let imageWidth: CGFloat = 40
    static let imageHeight: CGFloat = 40
    static let imageCornerRadius: CGFloat = 20
}

struct SharingInfoView_Previews: PreviewProvider {
    static var previews: some View {
        SharingInfoAssemler.make(entityType: .room(.init()))
    }
}
