//
//  ASCChooseRoomTemplateMembersView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 08.06.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Kingfisher
import SwiftUI

struct ASCChooseRoomTemplateMembersView: View {
    @StateObject var viewModel: ASCChooseRoomTemplateMembersViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            header

            membersList

            footer
        }
        .onAppear { viewModel.onAppear() }
        .navigationTitle(NSLocalizedString("Select members", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
            }
        )
    }

    private var header: some View {
        VStack {
            searchBar
            segment
            describingText
        }
    }

    private var searchBar: some View {
        SearchBar(text: $viewModel.dataModel.searchText)
            .padding(.horizontal, 8)
    }

    private var segment: some View {
        Picker("Select", selection: $viewModel.dataModel.selectedSegment) {
            ForEach(ASCChooseRoomTemplateMembersViewModel.Segment.allCases) { segment in
                Text(verbatim: segment.localizedString).tag(segment)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal, 16)
    }

    private var describingText: some View {
        let text = if viewModel.dataModel.selectedSegment == .users {
            NSLocalizedString("Only DocSpace and Room admins are shown here", comment: "")
        } else if viewModel.dataModel.selectedSegment == .groups {
            NSLocalizedString("Only DocSpace and Room admins from the selected groups will be able to create rooms using this template.", comment: "")
        } else {
            ""
        }
        return Group {
            if !text.isEmpty {
                Text(verbatim: text)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical)
            }
        }
    }

    @ViewBuilder
    private var membersList: some View {
        List {
            ForEach(viewModel.screenModel.rows) { cell in
                switch cell {
                case let .user(model):
                    ASCRoomTemplateMemberRow(model: .user(model))
                case let .group(model):
                    ASCRoomTemplateMemberRow(model: .group(model))
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button(action: {
                viewModel.addSelectedMembers()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Add")
                    .fontWeight(.semibold)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 16)
                    .background(
                        viewModel.screenModel.isAddButtonEnabled
                            ? Asset.Colors.brend.swiftUIColor
                            : Color.gray
                    )
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .disabled(!viewModel.screenModel.isAddButtonEnabled)
        }
        .padding()
        .background(
            Color(.systemBackground).ignoresSafeArea()
        )
    }
}

enum ASCRoomTemplateMemberRowModel {
    case user(ASCRoomTemplateUserMemberRowModel)
    case group(ASCRoomTemplateGroupMemberRowModel)
}
