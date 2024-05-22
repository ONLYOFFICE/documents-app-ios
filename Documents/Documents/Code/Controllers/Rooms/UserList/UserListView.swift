//
//  UserListView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 16.05.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation
import MBProgressHUD
import SwiftUI

struct UserListView: View {
    @ObservedObject var viewModel: UserListViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            SearchBar(text: $viewModel.searchText)
            if viewModel.isLoading {
                Spacer()
                ActivityIndicatorView()
                Spacer()
            } else {
                List(viewModel.users) { user in
                    UserRow(user: user)
                        .onTapGesture {
                            if let selectedUser = viewModel.allUsers.first(where: { $0.userId == user.id }) {
                                viewModel.selectedUser = selectedUser
                            }
                            presentationMode.wrappedValue.dismiss()
                        }
                }
            }
        }
        .navigationBarTitle(Text(NSLocalizedString("Change room's owner", comment: "")), displayMode: .inline)
        .navigationBarItems(trailing: cancelButton)
    }

    var cancelButton: some View {
        Button(NSLocalizedString("Cancel", comment: "")) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct UserRow: View {
    typealias User = UserList.User

    let user: User

    var body: some View {
        HStack {
            if let url = user.imageUrl {
                KFImageView(url: url)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .cornerRadius(20)
                    .clipped()
            } else {
                Image(uiImage: Asset.Images.avatarDefault.image)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .cornerRadius(20)
                    .clipped()
            }
            VStack(alignment: .leading) {
                Text(user.name)
                    .font(.headline)
                Text("\(user.role) | \(user.email)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.vertical, 5)
    }
}

struct SearchBar: UIViewRepresentable {
    @Binding var text: String

    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.backgroundImage = UIImage()
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            UserListView(viewModel: UserListViewModel(selectedUser: .constant(nil), ignoreUserId: nil))
        }
    }
}
