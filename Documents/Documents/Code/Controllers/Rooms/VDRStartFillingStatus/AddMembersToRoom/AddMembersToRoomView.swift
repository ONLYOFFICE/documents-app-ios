//
//  AddMembersToRoomView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 22/08/25.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Kingfisher
import SwiftUI

struct AddMembersToRoomView: View {
    @StateObject var viewModel: AddMembersToRoomViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack {
                header

                membersList

                footer
            }

            placeHolder

            if viewModel.dataModel.isLoading {
                OverlayLoader()
            }
        }
        .onAppear { viewModel.onAppear() }
        .navigationTitle(NSLocalizedString("Select members", comment: ""))
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
            ForEach(AddMembersToRoomViewModel.Segment.allCases) { segment in
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

    // MARK: - Placeholders

    @ViewBuilder
    private var placeHolder: some View {
        if viewModel.dataModel.areMembersFetched,
           viewModel.dataModel.selectedSegment == .users,
           viewModel.dataModel.users.isEmpty
        {
            noUsersView
        } else if viewModel.dataModel.areMembersFetched,
                  viewModel.dataModel.selectedSegment == .guests,
                  viewModel.dataModel.guests.isEmpty
        {
            noGuestsView
        }
    }

    private var noUsersView: some View {
        Text("There are no users to add")
            .padding(.all)
    }

    private var noGuestsView: some View {
        Text("There are no guests to add")
            .padding(.all)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.secondary)
                .frame(height: 0.5)

            HStack {
                Menu {
                    ForEach(viewModel.availableAccess, id: \.self) { access in
                        Button(access.title()) {
                            viewModel.setAccess(access)
                        }
                    }
                } label: {
                    Text(viewModel.dataModel.selectedAccess.title())
                        .brandButton(.inline)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                }
                Spacer()
                Button("Add to room", action: {
                    viewModel.addSelectedToRoom {
                        presentationMode.wrappedValue.dismiss()
                    }
                })
                .brandButton(.filledCapsule)
                .disabled(viewModel.dataModel.isLoading || viewModel.dataModel.selectedUsers.isEmpty)
            }
            .padding()
        }
        .background(
            Color(.secondarySystemGroupedBackground).ignoresSafeArea(edges: [.horizontal, .bottom])
        )
    }
}
