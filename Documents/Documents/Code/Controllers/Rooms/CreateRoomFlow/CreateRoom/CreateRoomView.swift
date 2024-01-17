//
//  CreateRoomView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 22.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation
import MBProgressHUD
import SwiftUI

struct CreateRoomView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var viewModel: CreateRoomViewModel
    @State var isRoomSelectionPresenting = false

    var body: some View {
        handleHUD()

        return List {
            roomTypeSection
            roomImageAndNameSection
            roomTagsSection
        }
        .navigation(isActive: $isRoomSelectionPresenting, destination: {
            RoomSelectionView(
                selectedRoomType: Binding<RoomTypeModel?>(
                    get: { viewModel.selectedRoomType },
                    set: { newValue in
                        if let newValue {
                            viewModel.selectedRoomType = newValue
                        }
                    }
                ),
                dismissOnSelection: true
            )
        })
        .navigationBarTitle(Text(NSLocalizedString("Create room", comment: "")), displayMode: .inline)
        .navigationBarItems(
            trailing: Button(NSLocalizedString("Create", comment: "")) {
                viewModel.createRoom()
            }
            .disabled(viewModel.roomName.isEmpty || viewModel.isCreatingRoom)
        )
        .alert(item: $viewModel.errorMessage) { errorMessage in
            Alert(
                title: Text(ASCLocalization.Common.error),
                message: Text(errorMessage),
                dismissButton: .default(Text(ASCLocalization.Common.ok), action: {
                    viewModel.errorMessage = nil
                })
            )
        }
    }

    private var roomTypeSection: some View {
        Section {
            RoomTypeViewRow(roomTypeModel: viewModel.selectedRoomType)
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
            TagsFieldView(tags: $viewModel.tags, deletedTags: $viewModel.tags)
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

    private func handleHUD() {
        if viewModel.isCreatingRoom {
            MBProgressHUD.currentHUD?.hide(animated: false)
            let hud = MBProgressHUD.showTopMost()
            hud?.mode = .indeterminate
            hud?.label.text = NSLocalizedString("Creating", comment: "Caption of the processing")
        } else {
            if let hud = MBProgressHUD.currentHUD {
                if let _ = viewModel.errorMessage {
                    hud.hide(animated: true)
                } else {
                    hud.setState(result: .success(nil))
                    hud.hide(animated: true, afterDelay: 1.3)
                }
            }
        }
    }
}

#Preview {
    CreateRoomView(
        viewModel: CreateRoomViewModel(selectedRoomType: CreatingRoomType.publicRoom.toRoomTypeModel()) { _ in }
    )
}
