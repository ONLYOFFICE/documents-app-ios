//
//  ASCChooseRoomTemplateMembersView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 08.06.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI
import Kingfisher

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
        .navigationTitle("Select members")
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
                Text(segment.rawValue).tag(segment)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal, 16)
    }
    
    
    private var describingText: some View {
        let text = if viewModel.dataModel.selectedSegment == .users {
            "Only DocSpace and Room admins are shown here"
        } else if viewModel.dataModel.selectedSegment == .groups {
            "Only DocSpace and Room admins from the selected groups will be able to create rooms using this template."
        } else {
            ""
        }
        return Group {
            if !text.isEmpty {
                Text(text)
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
            return ForEach(viewModel.screenModel.rows) { cell in
                switch cell {
                case .user(let model):
                    ASCRoomTemplateMemberRow(model: .user(model))
                case .group(let model):
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
