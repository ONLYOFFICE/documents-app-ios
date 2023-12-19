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
        .navigationBarTitle(Text(NSLocalizedString("\(viewModel.roomName)", comment: ""))) // TODO: - add subtitle
    }

    private var generalLincSection: some View {
        Section(header: Text(NSLocalizedString("General link", comment: ""))) {
            RoomSharingLinkRow(title: "Shared link", images: []) {
                print("action")
            }
        }
    }

    private var additionalLinksSection: some View {
        Section(header: Text(NSLocalizedString("Additional links", comment: ""))) {}
    }

    private var adminSection: some View {
        Section(header: Text(NSLocalizedString("Administration", comment: ""))) {}
    }

    private var usersSection: some View {
        Section(header: Text(NSLocalizedString("Users", comment: ""))) {}
    }
}

struct RoomSharingView_Previews: PreviewProvider {
    static var previews: some View {
        RoomSharingView(viewModel: .init(roomName: "1", roomType: "2", additionalLinks: [], users: [], admins: []))
    }
}

struct RoomSharingLinkRow: View {
    var title: String
    var images: [String]
    var onShareAction: () -> Void

    var body: some View {
        HStack {
            Image(uiImage: Asset.Images.navLink.image)
                .resizable()
                .background(Color(asset: Asset.Colors.tableCellSelected))
                .frame(width: 40, height: 40)
                .cornerRadius(40)
            VStack {
                Text(title)
                HStack {
                    //
                }
            }
            Spacer()
            HStack(spacing: 16) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(Asset.Colors.brend.swiftUIColor)
                    .onTapGesture {
                        onShareAction()
                    }
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(Color.separator)
                    .flipsForRightToLeftLayoutDirection(true)
            }
        }
    }
}
