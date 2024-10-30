//
//  InviteUsersView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 19.05.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation
import MBProgressHUD
import SwiftUI

struct InviteUsersView: View {
    @ObservedObject var viewModel: InviteUsersViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            List {
                externalLinkSection

                Section(header: Text(NSLocalizedString("Add manually", comment: ""))) {
                    inviteByEmailCell
                    chooseFromListCell
                }
            }
        }
        .navigationBarTitle(Text(NSLocalizedString("Invite users", comment: "")), displayMode: .inline)
        .navigationBarItems(trailing: cancelButton)
        .navigateToInviteByEmail(isDisplaying: $viewModel.isInviteByEmailsScreenDisplaying, viewModel: viewModel)
        .navigateToAddUsers(isDisplaying: $viewModel.isAddUsersScreenDisplaying, viewModel: viewModel)
        .sharingSheet(isPresented: $viewModel.isSharingScreenPresenting, link: viewModel.sharingLink)
        .onAppear {
            viewModel.fetchData()
        }
        .background(handleHUD())
    }

    var cancelButton: some View {
        Button(NSLocalizedString("Cancel", comment: "")) {
            presentationMode.wrappedValue.dismiss()
            viewModel.dismissAction?()
        }
    }

    @ViewBuilder
    private var externalLinkSection: some View {
        if viewModel.isExternalLinkSectionAvailable {
            Section(header: Text(NSLocalizedString("External link", comment: ""))) {
                linkToggleCell
                if viewModel.externalLink != nil {
                    accessCell
                    linkCell
                }
            }
        }
    }

    private var linkToggleCell: some View {
        Toggle(isOn: $viewModel.isExternalLinkSwitchActive) {
            Text(NSLocalizedString("Link", comment: ""))
        }
        .tintColor(Asset.Colors.brend.swiftUIColor)
    }

    private var accessCell: some View {
        MenuView(menuItems: viewModel.accessMenuItems) {
            HStack {
                Text(NSLocalizedString("Access rights", comment: ""))
                    .foregroundColor(.primary)
                Spacer()
                Text(viewModel.selectedAccessRight.title())
                    .foregroundColor(.gray)
                ChevronUpDownView()
            }
        }
    }

    private var linkCell: some View {
        HStack {
            Text(viewModel.linkStr)
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
            Button(action: {
                UIPasteboard.general.string = viewModel.linkStr
                viewModel.shareLink()
            }) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(Asset.Colors.brend.swiftUIColor)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.shareLink()
        }
    }

    private var inviteByEmailCell: some View {
        HStack {
            Text(NSLocalizedString("Invite people by email", comment: ""))
            Spacer()
            ChevronRightView()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.isInviteByEmailsScreenDisplaying = true
        }
    }

    private var chooseFromListCell: some View {
        HStack {
            Text(NSLocalizedString("Choose from list", comment: ""))
            Spacer()
            ChevronRightView()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.isAddUsersScreenDisplaying = true
        }
    }

    private func handleHUD() -> some View {
        EmptyView().onAppear {
            MBProgressHUD.currentHUD?.hide(animated: false)
            if viewModel.isLoading {
                let hud = MBProgressHUD.showAdded(to: UIApplication.shared.windows.first!, animated: true)
                hud.mode = .indeterminate
                hud.label.text = NSLocalizedString("Loading", comment: "") + "..."
            } else {
                MBProgressHUD.hide(for: UIApplication.shared.windows.first!, animated: true)
            }
        }
    }
}

// MARK: - Navigation

private extension View {
    func navigateToInviteByEmail(
        isDisplaying: Binding<Bool>,
        viewModel: InviteUsersViewModel
    ) -> some View {
        navigation(isActive: isDisplaying) {
            InviteRigthHoldersByEmailsRepresentable(entity: viewModel.room)
                .navigationBarHidden(true)
        }
    }

    func navigateToAddUsers(
        isDisplaying: Binding<Bool>,
        viewModel: InviteUsersViewModel
    ) -> some View {
        navigation(isActive: isDisplaying) {
            SharingInviteRightHoldersRepresentable(entity: viewModel.room)
                .navigationBarHidden(true)
        }
    }

    func sharingSheet(isPresented: Binding<Bool>, link: URL?) -> some View {
        sheet(isPresented: isPresented) {
            if let link {
                ActivityView(activityItems: [link])
            }
        }
    }
}

struct InviteUsersView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            InviteUsersView(
                viewModel: InviteUsersViewModel(
                    room: ASCRoom()
                )
            )
        }
    }
}
