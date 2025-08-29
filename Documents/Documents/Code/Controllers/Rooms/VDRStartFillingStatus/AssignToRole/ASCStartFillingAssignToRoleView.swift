//
//  ASCStartFillingAssignToRoleView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 12/08/25.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Kingfisher
import SwiftUI

struct ASCStartFillingAssignToRoleView: View {
    @StateObject var viewModel: ASCStartFillingAssignToRoleViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            header

            membersList

            footer
        }
        .background(Color(.secondarySystemBackground))
        .onAppear { viewModel.onAppear() }
        .navigateToAddMembersToRoom(isActive: $viewModel.router.isAddToRoomDisplaying, viewModel: viewModel)
        .navigationTitle(NSLocalizedString("Assign to role", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            trailing: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Cancel")
            }
        )
    }

    private var header: some View {
        VStack {
            searchBar
            segment
        }
    }

    private var searchBar: some View {
        SearchBar(text: $viewModel.dataModel.searchText, placeholder: "Search")
            .padding(.horizontal, 8)
    }

    private var segment: some View {
        Picker("Select", selection: $viewModel.dataModel.selectedSegment) {
            ForEach(ASCStartFillingAssignToRoleViewModel.Segment.allCases) { segment in
                Text(verbatim: segment.localizedString).tag(segment)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var membersList: some View {
        List {
            ForEach(viewModel.screenModel.rows) { cell in
                switch cell {
                case let .user(model):
                    ASCRoomTemplateMemberRow(model: .user(model))
                case let .guest(model):
                    ASCRoomTemplateMemberRow(model: .user(model))
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.secondary)
                .frame(height: 0.5)

            HStack {
                Spacer()
                Button(action: {
                    viewModel.router.isAddToRoomDisplaying = true
                }) {
                    Text("Add user to room")
                        .brandButton(.filledCapsule)
                }
            }
            .padding()
        }
        .background(
            Color(.systemBackground).ignoresSafeArea(edges: [.horizontal, .bottom])
        )
    }
}

// MARK: - Navigation

private extension View {
    @ViewBuilder
    func navigateToAddMembersToRoom(isActive: Binding<Bool>, viewModel: ASCStartFillingAssignToRoleViewModel) -> some View {
        navigation(isActive: isActive, destination: {
            AddMembersToRoomView(
                viewModel: AddMembersToRoomViewModel(
                    room: viewModel.room,
                    hiddenUsers: viewModel.dataModel.users + viewModel.dataModel.guests,
                    onAdd: { users in
                        viewModel.addedToRoom(members: users)
                        viewModel.router.isAddToRoomDisplaying = false
                    }
                )
            )
        })
    }
}
