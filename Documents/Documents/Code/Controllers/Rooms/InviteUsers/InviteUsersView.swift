//
//  InviteUsersView.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 19.05.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation
import SwiftUI
import MBProgressHUD

struct InviteUsersView: View {
    @ObservedObject var viewModel: InviteUsersViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            List {
                Section(header: Text(NSLocalizedString("External link", comment: ""))) {
                    Toggle(isOn: $viewModel.isLinkEnabled) {
                        Text(NSLocalizedString("Link", comment: ""))
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue))

                    NavigationLink(destination: ASCShareAccess(selectedAccessRight: $viewModel.selectedAccessRight)) {
                        HStack {
                            Text(NSLocalizedString("Access rights", comment: ""))
                            Spacer()
                            Text(viewModel.selectedAccessRight.rawValue)
                                .foregroundColor(.gray)
                        }
                    }
                    
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

                Section(header: Text(NSLocalizedString("Add manually", comment: ""))) {
                    // TODO: -
//                    NavigationLink(destination: InviteByEmailView()) {
//                        Text("Invite people by email")
//                    }
//                    NavigationLink(destination: ChooseFromListView(viewModel: viewModel)) {
//                        Text("Choose from list")
//                    }
                }
            }
        }
        .navigationBarTitle(NSLocalizedString("Invite users", comment: ""), displayMode: .inline)
        .navigationBarItems(trailing: cancelButton)
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

struct InviteUsersView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            // TODO: -
            //InviteUsersView(viewModel: InviteUsersViewModel())
        }
    }
}
