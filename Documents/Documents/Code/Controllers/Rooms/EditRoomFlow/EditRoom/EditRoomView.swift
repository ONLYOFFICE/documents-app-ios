//
//  EditRoomView.swift
//  Documents
//
//  Created by Victor Tihovodov on 10.01.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation
import MBProgressHUD
import SwiftUI

struct EditRoomView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var viewModel: EditRoomViewModel
    @State var isRoomSelectionPresenting = false

    var body: some View {
        handleHUD()

        return NavigationView {
            List {
                roomTypeSection
                roomImageAndNameSection
                roomTagsSection
            }
            .navigation(isActive: $isRoomSelectionPresenting, destination: {
                RoomSelectionView(selectedRoomType: $viewModel.selectedRoom, dismissOnSelection: true)
            })
            .navigationBarTitle(Text(NSLocalizedString("Edit room", comment: "")), displayMode: .inline)
            .navigationBarItems(
                leading: Button(NSLocalizedString("Close", comment: "")) {
                    viewModel.closeEdit()
                },
                trailing: Button(NSLocalizedString("Save", comment: "")) {
                    viewModel.editRoom(folder: viewModel.folder)
                }
                .disabled(viewModel.roomName.isEmpty || viewModel.isEditingRoom)
            )
            .alert(item: $viewModel.errorMessage) { errorMessage in
                Alert(
                    title: Text(ASCLocalization.Common.error),
                    message: Text(errorMessage),
                    dismissButton: .default(ASCLocalization.Common.ok, action: {
                        viewModel.errorMessage = nil
                    })
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var roomTypeSection: some View {
        Section {
            RoomTypeViewRow(roomTypeModel: viewModel.selectedRoom)
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
            TagsFieldView(tags: $viewModel.tags, deletedTags: $viewModel.deletedTags)
                .listRowInsets(EdgeInsets())
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
            .disabled(viewModel.isEditingRoom)
    }

    private func handleHUD() {
        if viewModel.isEditingRoom {
            MBProgressHUD.currentHUD?.hide(animated: false)
            let hud = MBProgressHUD.showTopMost()
            hud?.mode = .indeterminate
            hud?.label.text = NSLocalizedString("Updating", comment: "Caption of the processing")
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
