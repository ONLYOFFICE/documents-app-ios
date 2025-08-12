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
            ForEach(ASCChooseRoomTemplateMembersViewModel.Segment.allCases) { segment in
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
                    ASCRoomTemplateMemberRow(model: .user(model)) // TODO: support guest
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
                    // TODO: action to open new screen
                }) {
                    Text("Add user to room")
                        .fontWeight(.semibold)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 16)
                        .background(
                            Asset.Colors.brend.swiftUIColor
                        )
                        .foregroundColor(.white)
                        .cornerRadius(14)

                    // MARK: TODO modifier
                }
                .disabled(!viewModel.screenModel.isAddButtonEnabled)
            }
            .padding()
        }
        .background(
            Color(.systemBackground).ignoresSafeArea(edges: [.horizontal, .bottom])
        )
    }
}
