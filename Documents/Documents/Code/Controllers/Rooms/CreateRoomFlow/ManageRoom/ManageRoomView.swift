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

    var body: some View {
        handleHUD()

        return List {
            roomTypeSection
            roomImageAndNameSection
            roomTagsSection
            roomOwnerSection
            thirdPartySection
            automaticIndexationSection
            fileLifetimeSection
            restrictContentCopySection
            watermarkSection
            watermarkElementsSection
            watermarkStaticTextSection
            watermarkPositionSection
        }
        .onTapGesture {
            hideKeyboard()
        }
        .insetGroupedListStyle()
        .navigateToRoomTypeSelection(isActive: $viewModel.isRoomSelectionPresenting, viewModel: viewModel)
        .navigateToUserSelection(isActive: $viewModel.isUserSelectionPresenting, viewModel: viewModel)
        .sheet(isPresented: $viewModel.isStorageSelectionPresenting, content: {
            ASCConnectCloudViewControllerRepresentable(completion: viewModel.didCloudProviderLoad)
        })
        .sheet(isPresented: $viewModel.isFolderSelectionPresenting, content: {
            if let provider = viewModel.provider, let rootFolder = viewModel.thirdPartyFolder {
                ASCTransferViewControllerRepresentable(
                    provider: provider,
                    rootFolder: rootFolder,
                    completion: viewModel.selectFolder
                )
            }
        })
        .navigationTitle(isEditMode: viewModel.isEditMode)
        .navigationBarItems(viewModel: viewModel)
        .alertForErrorMessage($viewModel.errorMessage)
    }

    // MARK: - All rooms sections

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
                    ChevronRightView()
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
                        .foregroundColor(Asset.Colors.brend.swiftUIColor)
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

    // MARK: - Public room third part section

    @ViewBuilder
    private var thirdPartySection: some View {
        if viewModel.selectedRoomType.type == .publicRoom && !viewModel.isEditMode {
            Section(
                footer: Text(
                    NSLocalizedString("Use third-party services as data storage for this room. A new folder for storing this room’s data will be created in the connected storage", comment: "")
                )
            ) {
                thirdPartyToggleCell
                if viewModel.isThirdPartyStorageEnabled {
                    storageSelectionCell
                    folderSelectionCell
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
            Text(NSLocalizedString("Third party storage", comment: ""))
        }
        .tintColor(Color(Asset.Colors.brend.color))
    }

    private var storageSelectionCell: some View {
        HStack(spacing: 4) {
            Text(NSLocalizedString("Storage", comment: ""))
            Spacer()
            Text(viewModel.selectedStorage ?? "")
                .foregroundColor(.gray)
            ChevronRightView()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.didTapStorageSelectionCell()
        }
    }

    private var folderSelectionCell: some View {
        HStack {
            Text(NSLocalizedString("Location", comment: ""))
            Spacer()
            Text(viewModel.selectedLocation)
                .foregroundColor(.gray)
            ChevronRightView()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.didTapSelectedFolderCell()
        }
    }

    private var createNewFolderCell: some View {
        Toggle(isOn: $viewModel.isCreateNewFolderEnabled) {
            Text(NSLocalizedString("Create new folder", comment: ""))
        }
        .tintColor(Color(Asset.Colors.brend.color))
    }

    // MARK: - VDR indexing section

    @ViewBuilder
    private var automaticIndexationSection: some View {
        if viewModel.selectedRoomType.type == .virtualData {
            Section(
                footer: Text(
                    NSLocalizedString("Enable automatic indexing to index files and folders by serial number. Sorting by number will be set as default for all users.", comment: "")
                )
            ) {
                automaticIndexingCell
            }
        }
    }

    private var automaticIndexingCell: some View {
        Toggle(isOn: $viewModel.isAutomaticIndexing) {
            Text(NSLocalizedString("Automatic indexing", comment: ""))
        }
        .tintColor(Color(Asset.Colors.brend.color))
    }

    // MARK: - VDR file lifetime section

    @ViewBuilder
    private var fileLifetimeSection: some View {
        if viewModel.selectedRoomType.type == .virtualData {
            Section(
                footer: Text(
                    NSLocalizedString("Set file lifetime to automatically delete the files in this room after a defined period. Lifetime begins on the date of upload/creation of the file.", comment: "")
                )
            ) {
                filesLifetimeCell
                filesOlderThanCell
                filesTimePeriodCell
                actionOnFilesCell
            }
        }
    }

    private var filesLifetimeCell: some View {
        Toggle(isOn: $viewModel.isFileLifetimeEnabled) {
            Text(NSLocalizedString("File lifetime", comment: ""))
        }
        .tintColor(Color(Asset.Colors.brend.color))
    }

    @ViewBuilder
    private var filesOlderThanCell: some View {
        if viewModel.isFileLifetimeEnabled {
            HStack {
                Text(NSLocalizedString("Files older than", comment: ""))
                Spacer()
                TextField("", value: $viewModel.fileAge, formatter: viewModel.fileAgeNumberFormatter)
                    .frame(width: 80)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
            }
        }
    }

    @ViewBuilder
    private var filesTimePeriodCell: some View {
        if viewModel.isFileLifetimeEnabled {
            MenuView(menuItems: viewModel.filesTimePeriodMenuItems) {
                HStack {
                    Text(NSLocalizedString("Time period", comment: ""))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(viewModel.selectedTemePeriod.localizedDesc)
                        .foregroundColor(.gray)
                    ChevronUpDownView()
                }
            }
        }
    }

    @ViewBuilder
    private var actionOnFilesCell: some View {
        if viewModel.isFileLifetimeEnabled {
            MenuView(menuItems: viewModel.actionOnFilesMenuItems) {
                HStack {
                    Text(NSLocalizedString("Action on files", comment: ""))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(viewModel.actionOnFiles.localizedDesc)
                        .foregroundColor(.gray)
                    ChevronUpDownView()
                }
            }
        }
    }

    // MARK: - VDR restrict content copy section

    @ViewBuilder
    private var restrictContentCopySection: some View {
        if viewModel.selectedRoomType.type == .virtualData {
            Section(
                footer: Text(
                    NSLocalizedString("Enable this seting to disable downloads, printing, and content copying for users with the “Viewer” role", comment: "")
                )
            ) {
                restrictContentCopyCell
            }
        }
    }

    private var restrictContentCopyCell: some View {
        Toggle(isOn: $viewModel.isRestrictContentCopy) {
            Text(NSLocalizedString("Restrict file content copy, file download and printing", comment: ""))
        }
        .tintColor(Color(Asset.Colors.brend.color))
    }

    // MARK: - VDR watermark section

    @ViewBuilder
    private var watermarkSection: some View {
        if viewModel.selectedRoomType.type == .virtualData {
            Section(
                footer: viewModel.isWatermarkEnabled
                    ? AnyView(EmptyView())
                    : AnyView(Text(NSLocalizedString("Protect all documents in this room with watermarks. If a document already contains one, it will not be replaced.", comment: "")))
            ) {
                watermarkToggleCell
                watermarkTypeCell
            }
        }
    }

    private var watermarkToggleCell: some View {
        Toggle(isOn: $viewModel.isWatermarkEnabled) {
            Text(NSLocalizedString("Add watermarks to documents", comment: ""))
        }
        .tintColor(Color(Asset.Colors.brend.color))
    }

    @ViewBuilder
    private var watermarkTypeCell: some View {
        if viewModel.isWatermarkEnabled {
            HStack {
                Text(NSLocalizedString("Watermark type", comment: ""))
                Spacer()
                MenuView(menuItems: viewModel.watermarkTypeMenuItems) {
                    HStack {
                        Text(viewModel.selectedWatermarkType.localizedDesc)
                            .foregroundColor(.gray)
                        ChevronUpDownView()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var watermarkElementsSection: some View {
        if viewModel.isWatermarkEnabled, viewModel.selectedWatermarkType == .viewerInfo {
            Section(header: Text(NSLocalizedString("Add watermark elements", comment: ""))) {
                ToggleButtonCollectionView(
                    buttonModels: viewModel.watermarkElementButtons,
                    width: UIScreen.main.bounds.width - 4 * 20
                )
                .padding(.top, 4)
            }
            .listRowInsets(.init(top: 0, leading: 20, bottom: 0, trailing: 20))
            .listRowBackground(Color.clear)
        }
    }

    @ViewBuilder
    private var watermarkStaticTextSection: some View {
        if viewModel.isWatermarkEnabled, viewModel.selectedWatermarkType == .viewerInfo {
            Section {
                HStack {
                    TextField(NSLocalizedString("Add static text", comment: ""), text: $viewModel.watermarkStaticText)
                        .foregroundColor(.gray)
                        .disabled(viewModel.isSaving)
                }
            }
        }
    }

    @ViewBuilder
    private var watermarkPositionSection: some View {
        if viewModel.isWatermarkEnabled, viewModel.selectedWatermarkType == .viewerInfo {
            Section(
                footer: Text(
                    NSLocalizedString("Protect all documents in this room with watermarks. If a document already contains one, it will not be replaced.", comment: "")
                )
            ) {
                HStack {
                    Text(NSLocalizedString("Position", comment: ""))
                    Spacer()
                    MenuView(menuItems: viewModel.watermarkPositionMenuItems) {
                        HStack {
                            Text(viewModel.selectedWatermarkPosition.localizedDesc)
                                .foregroundColor(.gray)
                            ChevronUpDownView()
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var quotaSizeUnitCell: some View {
        if viewModel.isStorateQuotaEnabled {
            MenuView(menuItems: viewModel.quotaSizeUnitMenuItems) {
                HStack {
                    Text(NSLocalizedString("Measurement unit", comment: ""))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(viewModel.selectedSizeUnit.localizedDesc)
                        .foregroundColor(.gray)
                    ChevronUpDownView()
                }
            }
        }
    }

    // MARK: - HUD

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
        } else if viewModel.isConnecting {
            MBProgressHUD.currentHUD?.hide(animated: false)
            let hud = MBProgressHUD.showTopMost()
            hud?.mode = .indeterminate
            hud?.label.text = NSLocalizedString("Connecting", comment: "Caption of the processing")
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
                Text(verbatim: "/Files for test")
                    .foregroundColor(selectedLocation == "/Files for test" ? Asset.Colors.brend.swiftUIColor : .primary)
            }
            Button(action: {
                selectedLocation = "/Documents"
            }) {
                Text(verbatim: "/Documents")
                    .foregroundColor(selectedLocation == "/Documents" ? Asset.Colors.brend.swiftUIColor : .primary)
            }
        }
        .navigationBarTitle("Select Location", displayMode: .inline)
    }
}

private extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
