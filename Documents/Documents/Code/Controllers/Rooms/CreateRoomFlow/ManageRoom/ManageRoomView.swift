//
//  ManageRoomView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 22.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation
import MBProgressHUD
import SwiftUI

struct ManageRoomView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var viewModel: ManageRoomViewModel
    
    @State private var isThirdPartyStorageEnabled: Bool = false
    @State private var selectedLocation: String = "/Files for test"

    var body: some View {
        handleHUD()

        return List {
            roomTypeSection
            roomImageAndNameSection
            roomTagsSection
            roomOwnerSection
            thirdPartySection
        }
        .insetGroupedListStyle()
        .navigateToRoomTypeSelection(isActive: $viewModel.isRoomSelectionPresenting, viewModel: viewModel)
        .navigateToUserSelection(isActive: $viewModel.isUserSelectionPresenting, viewModel: viewModel)
        .navigateToStorageSelection(isActive: $viewModel.isStorageSelectionPresenting, viewModel: viewModel)
        .navigationTitle(isEditMode: viewModel.isEditMode)
        .navigationBarItems(viewModel: viewModel)
        .alertForErrorMessage($viewModel.errorMessage)
    }

    private var roomTypeSection: some View {
        Section {
            RoomTypeViewRow(roomTypeModel: viewModel.selectedRoomType)
                .onTapGesture {
                    guard !viewModel.isEditMode else { return }
                    viewModel.isRoomSelectionPresenting = true
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
    private var roomOwnerSection: some View {
        if viewModel.isEditMode {
            Section {
                HStack(spacing: 8) {
                    Text(NSLocalizedString("Owner", comment: ""))
                    Spacer()
                    Text(viewModel.roomOwnerName)
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundColor(Color.separator)
                        .flipsForRightToLeftLayoutDirection(true)
                }
                .onTapGesture {
                    viewModel.isUserSelectionPresenting = true
                }
            }
        }
    }

    @ViewBuilder
    private var imagePicker: some View {
        if let image = viewModel.selectedImage {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: .imageSideSize, height: .imageSideSize)
                .cornerRadius(.imageCornerRadious)
        } else if let url = viewModel.editingRoomImage {
            KFImageView(url: url)
                .frame(width: .imageSideSize, height: .imageSideSize)
                .cornerRadius(.imageCornerRadious)
                .clipped()
        } else {
            RoundedRectangle(cornerRadius: .imageCornerRadious)
                .frame(width: .imageSideSize, height: .imageSideSize)
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
            .onChange(of: viewModel.roomName) { newValue in
                viewModel.roomName = newValue.removeForbiddenCharacters()
            }
            .padding()
            .background(Color.secondarySystemGroupedBackground)
            .disabled(viewModel.isSaving)
    }
    
    @ViewBuilder
    private var thirdPartySection: some View {
        if viewModel.selectedRoomType.type == .publicRoom {
            Section(
                footer: Text(
                    NSLocalizedString("Use third-party services as data storage for this room. A new folder for storing this room’s data will be created in the connected storage", comment: "")
                )
            ) {
                thirdPartyToggleCell
                if viewModel.isThirdPartyStorageEnabled {
                    storageSelectionCell
                    // folderSelectionCell
                    createNewFolderCell
                }
            }
        }
    }
    
    private var thirdPartyToggleCell: some View {
        Toggle(isOn: Binding(
            get: { viewModel.isThirdPartyStorageEnabled },
            set: { viewModel.didTapThirdPartyStorageSwitch(isOn: $0) }
        )) {
            Text("Third party storage")
        }
        .tintColor(Color(Asset.Colors.brend.color))
    }
    
    private var storageSelectionCell: some View {
        HStack(spacing: 4) {
            Text("Storage")
            Spacer()
            Text(viewModel.selectedStorage ?? "")
                .foregroundColor(.gray)
            Image(systemName: "chevron.right")
                .font(.subheadline)
                .foregroundColor(Color.separator)
                .flipsForRightToLeftLayoutDirection(true)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.didTapStorageSelectionCell()
        }
    }
    
    private var folderSelectionCell: some View {
        NavigationLink(destination: LocationSelectionView(selectedLocation: $selectedLocation)) {
            HStack {
                Text("Location")
                Spacer()
                Text(selectedLocation)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var createNewFolderCell: some View {
        Toggle(isOn: $viewModel.isCreateNewFolderEnabled) {
            Text("Create new folder")
        }
        .tintColor(Color(Asset.Colors.brend.color))
    }

    private func handleHUD() {
        if viewModel.isSavedSuccessfully {
            if let hud = MBProgressHUD.currentHUD, viewModel.hideActivityOnSuccess {
                hud.setState(result: .success(nil))
                hud.hide(animated: true, afterDelay: .standardDelay)
            }
        } else if viewModel.isSaving {
            MBProgressHUD.currentHUD?.hide(animated: false)
            let hud = MBProgressHUD.showTopMost()
            hud?.mode = .indeterminate
            hud?.label.text = NSLocalizedString("Creating", comment: "Caption of the processing")
        } else if let hud = MBProgressHUD.currentHUD {
            if let _ = viewModel.errorMessage {
                hud.hide(animated: true)
            } else {
                hud.setState(result: .success(nil))
                hud.hide(animated: true, afterDelay: .standardDelay)
            }
        }
    }
}

// MARK: Modifiers

private extension View {
    @ViewBuilder
    func navigationBarItems(viewModel: ManageRoomViewModel) -> some View {
        let closeButton = Button(NSLocalizedString("Close", comment: "")) {
            UIApplication.topViewController()?.dismiss(animated: true)
        }
        let saveButton = Button(
            viewModel.isEditMode
                ? NSLocalizedString("Save", comment: "")
                : NSLocalizedString("Create", comment: "")
        ) {
            viewModel.save()
        }
        .disabled(viewModel.isSaveBtnEnabled)

        if viewModel.isEditMode {
            navigationBarItems(
                leading: closeButton,
                trailing: saveButton
            )
        } else {
            navigationBarItems(
                trailing: saveButton
            )
        }
    }

    func navigationTitle(isEditMode: Bool) -> some View {
        isEditMode
            ? navigationBarTitle(Text(NSLocalizedString("Edit room", comment: "")), displayMode: .inline)
            : navigationBarTitle(Text(NSLocalizedString("Create room", comment: "")), displayMode: .inline)
    }

    func navigateToRoomTypeSelection(isActive: Binding<Bool>, viewModel: ManageRoomViewModel) -> some View {
        navigation(isActive: isActive, destination: {
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
    }

    func navigateToUserSelection(isActive: Binding<Bool>, viewModel: ManageRoomViewModel) -> some View {
        navigation(isActive: isActive, destination: {
            UserListView(
                viewModel: UserListViewModel(
                    selectedUser: Binding<ASCUser?>(
                        get: { viewModel.newRoomOwner },
                        set: { newValue in
                            if let newValue {
                                viewModel.newRoomOwner = newValue
                                viewModel.roomOwnerName = newValue.displayName ?? ""
                            }
                        }
                    ),
                    ignoreUserId: viewModel.ignoreUserId
                )
            )
        })
    }
    
    func navigateToStorageSelection(isActive: Binding<Bool>, viewModel: ManageRoomViewModel) -> some View {
        navigation(isActive: isActive, destination: {
            ASCConnectCloudViewControllerRepresentable(completion: viewModel.didCloudProviderLoad)
        })
    }

    @ViewBuilder
    func insetGroupedListStyle() -> some View {
        if #available(iOS 14.0, *) {
            listStyle(InsetGroupedListStyle())
        }
    }
}

// MARK: Constants

private extension CGFloat {
    static let imageSideSize: CGFloat = 48
    static let imageCornerRadious: CGFloat = 8
}

#Preview {
    ManageRoomView(
        viewModel: ManageRoomViewModel(selectedRoomType: CreatingRoomType.publicRoom.toRoomTypeModel(showDisclosureIndicator: true)) { _ in }
    )
}

private extension String {
    func removeForbiddenCharacters() -> String {
        let forbiddenCharacters = "*+:\"<>?|/\\"
        return filter { !forbiddenCharacters.contains($0) }
    }
}

struct LocationSelectionView: View {
    @Binding var selectedLocation: String

    var body: some View {
        List {
            Button(action: {
                selectedLocation = "/Files for test"
            }) {
                Text("/Files for test")
                    .foregroundColor(selectedLocation == "/Files for test" ? .blue : .primary)
            }
            Button(action: {
                selectedLocation = "/Documents"
            }) {
                Text("/Documents")
                    .foregroundColor(selectedLocation == "/Documents" ? .blue : .primary)
            }
        }
        .navigationBarTitle("Select Location", displayMode: .inline)
    }
}
