//
//  ManageRoomViewModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 23.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation
import UIKit

class ManageRoomViewModel: ObservableObject {
    // MARK: - Published vars

    @Published var roomName: String = ""
    @Published var roomOwnerName: String = ""
    @Published var isSaving = false
    @Published var isSavedSuccessfully = false
    @Published var errorMessage: String?
    @Published var selectedRoomType: RoomTypeModel
    @Published var selectedImage: UIImage?
    @Published var tags: Set<String> = []

    @Published var selectedStorage: String?
    @Published var isCreateNewFolderEnabled: Bool = false

    @Published var isRoomSelectionPresenting = false
    @Published var isUserSelectionPresenting = false
    @Published var isStorageSelectionPresenting = false

    var newRoomOwner: ASCUser?
    var ignoreUserId: String?

    // MARK: - Public vars

    lazy var menuItems: [MenuViewItem] = makeImageMenuItems()
    let hideActivityOnSuccess: Bool
    var isEditMode: Bool { editingRoom != nil }
    var editingRoomImage: URL? {
        if let urlStr = editingRoom?.logo?.small,
           !urlStr.isEmpty,
           let portal = OnlyofficeApiClient.shared.baseURL?.absoluteString.trimmed
        {
            return URL(string: portal + urlStr)
        }
        return nil
    }

    var isSaveBtnEnabled: Bool {
        roomName.isEmpty || isSaving
    }

    var isThirdPartyStorageEnabled: Bool {
        provider != nil
    }

    // MARK: - Private vars

    private lazy var creatingRoomService = ServicesProvider.shared.roomCreateService
    private var onCreate: (ASCFolder) -> Void
    private let editingRoom: ASCRoom?
    private var provider: ASCFileProviderProtocol?
    private var thirdPartyFolder: ASCFolder?

    // MARK: - Init

    init(
        editingRoom: ASCRoom? = nil,
        selectedRoomType: RoomTypeModel,
        roomName: String = "",
        hideActivityOnSuccess: Bool = true,
        onCreate: @escaping (ASCFolder) -> Void
    ) {
        self.editingRoom = editingRoom
        self.selectedRoomType = selectedRoomType
        self.hideActivityOnSuccess = hideActivityOnSuccess
        self.onCreate = onCreate

        if let editingRoom {
            self.selectedRoomType.showDisclosureIndicator = false
            self.roomName = editingRoom.title
            roomOwnerName = editingRoom.createdBy?.displayName ?? ""
            ignoreUserId = editingRoom.createdBy?.userId
            tags = Set(editingRoom.tags ?? [])
        } else {
            self.roomName = roomName
        }
    }

    // MARK: - Public func

    func save() {
        isSaving = true
        if isEditMode {
            updateRoom()
        } else {
            createRoom()
        }
    }

    func didTapStorageSelectionCell() {
        isStorageSelectionPresenting = true
    }

    func didCloudProviderLoad(provider: ASCFileProviderProtocol, folder: ASCFolder, info: [String: Any]) {
        self.provider = provider
        thirdPartyFolder = folder
        selectedStorage = provider.externalProviderName()
    }

    func didTapThirdPartyStorageSwitch(isOn: Bool) {
        if isOn {
            isStorageSelectionPresenting = true
        } else {
            provider = nil
            isStorageSelectionPresenting = false
        }
    }
}

// MARK: - Private func

private extension ManageRoomViewModel {
    func createRoom() {
        creatingRoomService.createRoom(
            model: CreatingRoomModel(
                roomType: selectedRoomType.type.ascRoomType,
                name: roomName,
                image: selectedImage,
                tags: tags.map { $0 },
                createAsNewFolder: isCreateNewFolderEnabled,
                thirdPartyFolderId: thirdPartyFolder?.id
            )
        ) { [weak self] result in
            self?.isSaving = false
            switch result {
            case let .success(room):
                self?.isSavedSuccessfully = true
                self?.onCreate(room)
            case let .failure(error):
                self?.errorMessage = error.localizedDescription
            }
        }
    }

    func updateRoom() {
        guard let room = editingRoom else {
            isSaving = false
            return
        }
        creatingRoomService.editRoom(
            model: EditRoomModel(
                roomType: selectedRoomType.type.ascRoomType,
                room: room,
                name: roomName,
                image: selectedImage,
                ownerToChange: newRoomOwner,
                tagsToAdd: Array(tags.subtracting(room.tags ?? [])),
                tagsToDelete: Array(Set(room.tags ?? []).subtracting(tags))
            )
        ) { [weak self] result in
            switch result {
            case let .success(room):
                self?.onCreate(room)
            case let .failure(error):
                self?.errorMessage = error.localizedDescription
            }
            self?.isSaving = false
        }
    }

    func makeImageMenuItems() -> [MenuViewItem] {
        [
            .init(text: NSLocalizedString("Photo Library", comment: ""), systemImageName: "photo", action: imageFromLibraryAction),
            .init(text: NSLocalizedString("Take Photo", comment: ""), systemImageName: "camera", action: imageFromCameraAction),
            .init(text: NSLocalizedString("Choose Files", comment: ""), systemImageName: "folder", action: imageFromFilesAction),
        ]
    }

    func imageFromLibraryAction() {
        let attachManager = ASCAttachmentManager()
        let temporaryFolderName = UUID().uuidString
        guard let topController = topController() else { return }
        attachManager.storeFromLibrary(in: topController, to: temporaryFolderName) { [weak self] result in
            self?.handleImageSelection(result)
            attachManager.cleanup(for: temporaryFolderName)
        }
    }

    func imageFromCameraAction() {
        let attachManager = ASCAttachmentManager()
        let temporaryFolderName = UUID().uuidString
        guard let topController = topController() else { return }
        attachManager.storeFromCamera(in: topController, to: temporaryFolderName) { [weak self] result in
            self?.handleImageSelection(result)
            attachManager.cleanup(for: temporaryFolderName)
        }
    }

    func imageFromFilesAction() {
        let attachManager = ASCAttachmentManager()
        let temporaryFolderName = UUID().uuidString
        guard let topController = topController() else { return }
        attachManager.storeFromFiles(in: topController, to: temporaryFolderName) { [weak self] result in
            self?.handleImageSelection(result)
            attachManager.cleanup(for: temporaryFolderName)
        }
    }

    func handleImageSelection(_ result: Result<URL, Error>) {
        switch result {
        case let .success(url):
            selectedImage = UIImage(contentsOfFile: url.path)
        case let .failure(error):
            if let error = error as? ASCAttachmentManagerError, error == .canceled {
                return
            }
            errorMessage = error.localizedDescription
        }
    }

    func topController() -> UIViewController? {
        if var topController = UIWindow.keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            return topController
        }
        return nil
    }
}
