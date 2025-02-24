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
            storageQuotaSection
        }
        .hideKeyboardOnDrag()
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
        .alertForActiveAlert(activeAlert: $viewModel.activeAlert, viewModel: viewModel)
    }

    // MARK: - All rooms sections

    private var roomTypeSection: some View {
        Section {
            RoomTypeViewRow(roomTypeModel: viewModel.selectedRoomType)
                .contentShape(Rectangle())
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
                    if viewModel.isRoomOwnerCellTappable {
                        ChevronRightView()
                    }
                }
                .onTapGesture {
                    viewModel.didTapRoomOwnerCell()
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

    private var thirdPartySection: some View {
        ThirdPartySection(viewModel: viewModel)
    }

    // MARK: - VDR indexing section

    private var automaticIndexationSection: some View {
        AutomaticIndexationSection(viewModel: viewModel)
    }

    // MARK: - VDR file lifetime section

    private var fileLifetimeSection: some View {
        FileLifetimeSection(viewModel: viewModel)
    }

    // MARK: - VDR restrict content copy section

    private var restrictContentCopySection: some View {
        RestrictContentCopySection(viewModel: viewModel)
    }

    // MARK: - VDR watermark section

    private var watermarkSection: some View {
        WatermarkSection(viewModel: viewModel)
    }

    // MARK: - Storage quota section

    private var storageQuotaSection: some View {
        StorageQuotaSection(viewModel: viewModel)
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

// MARK: - Modifiers

private extension View {
    // MARK: View navigation extenstions

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

    // MARK: View alert extensions

    func alertForActiveAlert(
        activeAlert: Binding<ManageRoomView.ActiveAlert?>,
        viewModel: ManageRoomViewModel
    ) -> some View {
        alert(item: activeAlert) { alertType in
            return switch alertType {
            case .errorMessage:
                Alert(
                    title: Text(NSLocalizedString("Error", comment: "")),
                    message: Text(viewModel.errorMessage ?? ""),
                    dismissButton: .default(Text("OK")) {
                        viewModel.errorMessage = nil
                    }
                )
            case .filesLifetimeWarning:
                Alert(
                    title: Text(NSLocalizedString("Files with the exceeded lifetime will be deleted", comment: "")),
                    message: Text(NSLocalizedString("The lifetime count starts from the file creation date. If any files in this room exceed the set lifetime, they will be deleted.", comment: "")),
                    primaryButton: .default(Text(NSLocalizedString("Ok", comment: ""))),
                    secondaryButton: .cancel {
                        viewModel.isFileLifetimeEnabled = false
                    }
                )
            case .saveWithoutWatermark:
                Alert(
                    title: Text(NSLocalizedString("Warning", comment: "")),
                    message: Text(NSLocalizedString("You have not set a watermark to be applied to documents in this room. You can always add a watermark in the room editing settings. Continue without a watermark?", comment: "")),
                    primaryButton: .default(
                        Text(NSLocalizedString("Continue", comment: "")),
                        action: {
                            viewModel.didPrimaryActionTappedOnNoWatermarkAlert()
                        }
                    ),
                    secondaryButton: .cancel()
                )
            }
        }
    }

    // MARK: View hide keyboard

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - ActiveAlert subtype

extension ManageRoomView {
    enum ActiveAlert: String, Identifiable {
        var id: String {
            rawValue
        }

        case errorMessage
        case filesLifetimeWarning
        case saveWithoutWatermark
    }
}

// MARK: Constants

private extension CGFloat {
    static let imageSideSize: CGFloat = 36
    static let imageCornerRadious: CGFloat = 8
}

private extension String {
    func removeForbiddenCharacters() -> String {
        let forbiddenCharacters = "*+:\"<>?|/\\"
        return filter { !forbiddenCharacters.contains($0) }
    }
}

#Preview {
    ManageRoomView(
        viewModel: ManageRoomViewModel(selectedRoomType: CreatingRoomType.publicRoom.toRoomTypeModel(showDisclosureIndicator: true)) { _ in }
    )
}

struct HideKeyboardOnDrag: ViewModifier {
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture().onEnded { _ in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            )
    }
}

extension View {
    @ViewBuilder
    func hideKeyboardOnDrag() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollDismissesKeyboard(.immediately)
        } else {
            modifier(HideKeyboardOnDrag())
        }
    }
}
