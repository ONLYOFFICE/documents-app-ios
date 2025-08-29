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
            VStack {
                header

                membersList

                footer
            }

            if viewModel.dataModel.isLoading {
                OverlayLoader()
            }
        }
        .background(Color(.secondarySystemBackground))
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
                Button(action: {
                    viewModel.addSelectedToRoom {
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text("Add to room")
                        .brandButton(.filledCapsule, isEnabled: !(viewModel.dataModel.isLoading && viewModel.dataModel.selectedUsers.isEmpty))
                }
            }
            .padding()
        }
        .background(
            Color(.systemBackground).ignoresSafeArea(edges: [.horizontal, .bottom])
        )
    }
}
