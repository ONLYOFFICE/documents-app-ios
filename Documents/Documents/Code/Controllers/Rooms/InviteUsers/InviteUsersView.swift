//
//  InviteUsersView.swift
//  Documents-opensource
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
                Section(header: Text(NSLocalizedString("External link", comment: ""))) {
                    linkToggleCell
                    accessCell
                    linkCell
                }

                Section(header: Text(NSLocalizedString("Add manually", comment: ""))) {
                    inviteByEmailCell
                    chooseFromListCell
                }
            }
        }
        .navigationBarTitle(Text(NSLocalizedString("Invite users", comment: "")), displayMode: .inline)
        .navigationBarItems(trailing: cancelButton)
        .navigateToAddUsers(isDisplaying: $viewModel.isAddUsersScreenDisplaying, viewModel: viewModel)
        .onAppear {
            viewModel.fetchData()
        }
        .background(handleHUD())
    }

    var cancelButton: some View {
        Button(NSLocalizedString("Cancel", comment: "")) {
            presentationMode.wrappedValue.dismiss()
        }
    }

    private var linkToggleCell: some View {
        Toggle(isOn: $viewModel.isLinkEnabled) {
            Text(NSLocalizedString("Link", comment: ""))
        }
        .tintColor(Asset.Colors.brend.swiftUIColor)
    }

    private var accessCell: some View {
        HStack {
            Text(NSLocalizedString("Access rights", comment: ""))
            Spacer()
            Text(viewModel.selectedAccessRight.title())
                .foregroundColor(.gray)
            ChevronUpDownView()
        }
    }

    private var linkCell: some View {
        HStack {
            Text(viewModel.link)
                .foregroundColor(.blue)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            Button(action: {
                UIPasteboard.general.string = viewModel.link
            }) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.blue)
            }
        }
    }

    private var inviteByEmailCell: some View {
        HStack {
            Text(NSLocalizedString("Invite people by email", comment: ""))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.subheadline)
                .foregroundColor(Color.separator)
                .flipsForRightToLeftLayoutDirection(true)
        }
        .contentShape(Rectangle())
    }

    private var chooseFromListCell: some View {
        HStack {
            Text(NSLocalizedString("Choose from list", comment: ""))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.subheadline)
                .foregroundColor(Color.separator)
                .flipsForRightToLeftLayoutDirection(true)
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
    func navigateToAddUsers(
        isDisplaying: Binding<Bool>,
        viewModel: InviteUsersViewModel
    ) -> some View {
        navigation(isActive: isDisplaying) {
            SharingInviteRightHoldersRepresentable(entity: viewModel.room)
                .navigationBarHidden(true)
        }
    }
}

struct InviteUsersView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            InviteUsersView(
                viewModel: InviteUsersViewModel(
                    isLinkEnabled: true,
                    selectedAccessRight: .comment,
                    link: "https://www.google.com",
                    isLoading: false,
                    room: ASCRoom()
                )
            )
        }
    }
}
