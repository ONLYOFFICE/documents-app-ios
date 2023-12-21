//
//  CreateRoomView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 22.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation
import SwiftUI

struct CreateRoomView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var viewModel: CreateRoomViewModel
    @State var isRoomSelectionPresenting = false

    var body: some View {
        List {
            roomTypeSection
            roomImageAndNameSection
            roomTagsSection
        }
        .navigation(isActive: $isRoomSelectionPresenting, destination: {
            RoomSelectionView(selectedRoom: $viewModel.selectedRoom, dismissOnSelection: true)
        })
        .navigationBarTitle(Text(NSLocalizedString("Create room", comment: "")), displayMode: .inline)
        .navigationBarItems(
            trailing: Button(NSLocalizedString("Create", comment: "")) {
                viewModel.createRoom()
            }
            .disabled(viewModel.roomName.isEmpty || viewModel.isCreatingRoom)
        )
        .overlay(
            creatingRoomActivityView
        )
        .alert(item: $viewModel.errorMessage) { errorMessage in
            Alert(
                title: Text(NSLocalizedString("Error", comment: "")),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"), action: {
                    viewModel.errorMessage = nil
                })
            )
        }
    }

    private var roomTypeSection: some View {
        Section {
            CreatingRoomViewRow(room: viewModel.selectedRoom)
                .onTapGesture {
                    isRoomSelectionPresenting = true
                }
        }
    }

    private var roomImageAndNameSection: some View {
        Section {
            HStack {
                MenuView(menuItems: viewModel.menuItems) {
                    imagePicker
                }

                roomNameTextField
            }
        }
    }

    private var roomTagsSection: some View {
        Section {
            TagsFieldView(tags: $viewModel.tags)
                .listRowInsets(EdgeInsets())
                .background(Color.systemGroupedBackground)
        }
        .background(Color.secondarySystemGroupedBackground)
    }

    @ViewBuilder
    private var imagePicker: some View {
        if let image = viewModel.selectedImage {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 48)
                .cornerRadius(8)
        } else {
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 48, height: 48)
                .foregroundColor(Color(Asset.Colors.fillEditorsDocs.color))
                .overlay(
                    Image(systemName: "photo")
                        .frame(width: 24, height: 24)
                        .foregroundColor(.blue)
                )
        }
    }

    private var roomNameTextField: some View {
        TextField(NSLocalizedString("Room name", comment: ""), text: $viewModel.roomName)
            .padding()
            .background(Color.secondarySystemGroupedBackground)
            .disabled(viewModel.isCreatingRoom)
    }

    @ViewBuilder
    private var creatingRoomActivityView: some View {
        if viewModel.isCreatingRoom {
            MBProgressHUDView(
                isLoading: $viewModel.isCreatingRoom,
                text: NSLocalizedString("Creating...", comment: ""),
                delay: 0.3,
                successStatusText: viewModel.errorMessage == nil ? "" : nil
            )
        }
    }
}

#Preview {
    CreateRoomView(
        viewModel: CreateRoomViewModel(selectedRoom: CreatingRoomType.publicRoom.toRoom()) { _ in }
    )
}
