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
        .navigateToRoomTemplateAccessScreenPresenting(isActive: $viewModel.isRoomTemplateAccessScreenPresenting, viewModel: viewModel)
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
        .navigationTitle(viewModel: viewModel)
        .navigationBarItems(viewModel: viewModel)
        .alertForActiveAlert(activeAlert: $viewModel.activeAlert, viewModel: viewModel)
    }

    // MARK: - All rooms sections

    private var roomTypeSection: some View {
        Section {
            RoomTypeViewRow(
                roomTypeModel: viewModel.selectedRoomType.mapToRowModel(
                    onTap: {
                        guard !viewModel.isEditMode else { return }
                        viewModel.isRoomSelectionPresenting = true
                    }
                )
            )
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
        Section(footer: tagsFooter) {
            TagsFieldView(tags: $viewModel.tags)
                .listRowInsets(EdgeInsets())
                .background(Color.systemGroupedBackground)
        }
    }

    @ViewBuilder
    private var roomOwnerSection: some View {
        if viewModel.isEditMode {
            Section(footer: roomOwnerFooter) {
                HStack(spacing: 8) {
                    Text("Owner")
                    Spacer()
                    Text(verbatim: viewModel.roomOwnerName)
                        .foregroundColor(.secondary)
                    if viewModel.isRoomOwnerCellTappable {
                        ChevronRightView()
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.didTapRoomOwnerCell()
                }
            }
        }
    }
    
    
    @ViewBuilder
    private var tagsFooter: some View {
        switch viewModel.screenMode {
        case .editTemplate(_):
            Text ("Tags are applied to the room which will be created based on this template.")
        default:
            Text("")
        }
    }
    
    @ViewBuilder
    private var roomOwnerFooter: some View {
        switch viewModel.screenMode {
        case .editTemplate(_):
            Text ("Access to template. You can select members who can create rooms based on this template.")
        default:
            Text("")
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
        if viewModel.isSaving || viewModel.isConnecting {
            MBProgressHUD.showTopMost(mode: .indeterminate)
        } else if let hud = MBProgressHUD.currentHUD {
            if let result = viewModel.resultModalModel {
                switch result.result {
                case .success:
                    hud.setState(result: .success(result.message))
                case .failure:
                    hud.setState(result: .failure(result.message))
                }
                hud.hide(animated: true, afterDelay: .standardDelay)
                DispatchQueue.main.async {
                    viewModel.resultModalModel = nil
                }
            } else {
                hud.hide(animated: true)
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
            viewModel.screenMode.title
        ) {
            viewModel.save()
        }
        .disabled(viewModel.isSaveBtnEnabled)

        switch viewModel.screenMode {
        case .edit:
            navigationBarItems(
                leading: closeButton,
                trailing: saveButton
            )
        default:
            navigationBarItems(
                trailing: saveButton
            )
        }
    }

    @ViewBuilder
    func navigationTitle(viewModel: ManageRoomViewModel) -> some View {
        switch viewModel.screenMode {
        case let .edit(room):
            navigationBarTitle(Text("Edit room"), displayMode: .inline)
        case .create, .createFromTemplate:
            navigationBarTitle(Text("Create room"), displayMode: .inline)
        case .saveAsTemplate:
            navigationBarTitle(Text("Save as template"), displayMode: .inline)
        case .editTemplate(_):
            navigationBarTitle(Text("Edit template"), displayMode: .inline)
        }
    }

    func navigateToRoomTypeSelection(isActive: Binding<Bool>, viewModel: ManageRoomViewModel) -> some View {
        navigation(isActive: isActive, destination: {
            RoomSelectionView(
                viewModel: RoomSelectionViewModel(),
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
    func navigateToRoomTemplateAccessScreenPresenting(isActive: Binding<Bool>, viewModel: ManageRoomViewModel) -> some View {
        if let template = viewModel.editingRoom {
            navigation(isActive: isActive, destination: {
                ASCTemplateAccessSettingsView(viewModel: ASCTemplateAccessSettingsViewModel(template: template))
            })
        } else {
            EmptyView()
        }
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
                    title: Text("Error"),
                    message: Text(verbatim: viewModel.errorMessage ?? ""),
                    dismissButton: .default(Text("OK")) {
                        viewModel.errorMessage = nil
                    }
                )
            case .filesLifetimeWarning:
                Alert(
                    title: Text("Files with the exceeded lifetime will be deleted"),
                    message: Text("The lifetime count starts from the file creation date. If any files in this room exceed the set lifetime, they will be deleted."),
                    primaryButton: .default(Text("Ok")),
                    secondaryButton: .cancel {
                        viewModel.isFileLifetimeEnabled = false
                    }
                )
            case .saveWithoutWatermark:
                Alert(
                    title: Text("Warning"),
                    message: Text("You have not set a watermark to be applied to documents in this room. You can always add a watermark in the room editing settings. Continue without a watermark?"),
                    primaryButton: .default(
                        Text("Continue"),
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
        viewModel: ManageRoomViewModel(screenMode: .create, selectedRoomType: CreatingRoomType.publicRoom.toRoomTypeModel(showDisclosureIndicator: true)) { _ in }
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

extension ManageRoomScreenMode {
    var title: String {
        switch self {
        case .create, .saveAsTemplate, .createFromTemplate:
            return NSLocalizedString("Create", comment: "")
        case .edit, .editTemplate(_):
            return NSLocalizedString("Save", comment: "")
        }
    }
}
