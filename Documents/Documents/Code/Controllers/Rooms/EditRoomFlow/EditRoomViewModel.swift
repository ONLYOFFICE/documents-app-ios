//
//  EditRoomViewModel.swift
//  Documents-develop
//
//  Created by Victor Tihovodov on 10.01.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation
import UIKit

class EditRoomViewModel: ObservableObject {
    // MARK: - Published vars

    @Published var roomName: String = ""
    @Published var isEditingRoom = false
    @Published var errorMessage: String?
    @Published var selectedRoom: Room!
    @Published var folder: ASCFolder!
    @Published var selectedImage: UIImage?
    @Published var tags: Set<String> = []
    @Published var deletedTags: Set<String> = []

    // MARK: - Public vars

    lazy var menuItems: [MenuViewItem] = makeImageMenuItems()

    // MARK: - Private var

    private lazy var editRoomService: NetworkEditRoomServiceImp = NetworkEditRoomServiceImp()
    private var onEdited: (ASCFolder) -> Void

    // MARK: - Init

    init(folder: ASCFolder, onEdited: @escaping (ASCFolder) -> Void) {
        self.folder = folder
        self.onEdited = onEdited
        roomName = folder.title
        tags = Set<String>(folder.tags ?? [])
        editRoomService.getRoomIcon(folder: folder) {
            self.selectedImage = self.editRoomService.icon.image
        }
        selectedRoom = selectedFolderRoomType(folder: folder)
    }

    // MARK: - Public func

    func editRoom(folder: ASCFolder) {
        isEditingRoom = true
        editRoomService.editRoom(
            model: .init(
                roomType: selectedRoom.type.ascRoomType,
                name: roomName,
                image: selectedImage,
                tags: tags.map { $0 },
                deletedTags: deletedTags.map { $0 }
            ),
            folder: folder
        ) { [weak self] result in
            switch result {
            case let .success(folder):
                self?.topController()?.dismiss(animated: true)
                self?.onEdited(folder)
            case let .failure(error):
                self?.errorMessage = error.localizedDescription
            }
            self?.isEditingRoom = false
        }
    }

    // MARK: - Private func

    private func makeImageMenuItems() -> [MenuViewItem] {
        [
            .init(text: NSLocalizedString("Photo Library", comment: ""), systemImageName: "photo", action: imageFromLibraryAction),
            .init(text: NSLocalizedString("Take Photo", comment: ""), systemImageName: "camera", action: imageFromCameraAction),
            .init(text: NSLocalizedString("Choose Files", comment: ""), systemImageName: "folder", action: imageFromFilesAction),
        ]
    }

    private func imageFromLibraryAction() {
        let attachManager = ASCAttachmentManager()
        let temporaryFolderName = UUID().uuidString
        guard let topController = topController() else { return }
        attachManager.storeFromLibrary(in: topController, to: temporaryFolderName) { [weak self] result in
            self?.handleImageSelection(result)
            attachManager.cleanup(for: temporaryFolderName)
        }
    }

    private func imageFromCameraAction() {
        let attachManager = ASCAttachmentManager()
        let temporaryFolderName = UUID().uuidString
        guard let topController = topController() else { return }
        attachManager.storeFromCamera(in: topController, to: temporaryFolderName) { [weak self] result in
            self?.handleImageSelection(result)
            attachManager.cleanup(for: temporaryFolderName)
        }
    }

    private func imageFromFilesAction() {
        let attachManager = ASCAttachmentManager()
        let temporaryFolderName = UUID().uuidString
        guard let topController = topController() else { return }
        attachManager.storeFromFiles(in: topController, to: temporaryFolderName) { [weak self] result in
            self?.handleImageSelection(result)
            attachManager.cleanup(for: temporaryFolderName)
        }
    }

    private func handleImageSelection(_ result: Result<URL, Error>) {
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

    private func topController() -> UIViewController? {
        if var topController = UIWindow.keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            return topController
        }
        return nil
    }

    private func selectedFolderRoomType(folder: ASCFolder) -> Room {
        switch folder.roomType {
        case .colobaration:
            return Room(type: CreatingRoomType.collaboration, name: CreatingRoomType.collaboration.name, description: CreatingRoomType.collaboration.description, icon: CreatingRoomType.collaboration.icon)
        case .custom:
            return Room(type: CreatingRoomType.custom, name: CreatingRoomType.custom.name, description: CreatingRoomType.custom.description, icon: CreatingRoomType.custom.icon)
        case .public:
            return Room(type: CreatingRoomType.publicRoom, name: CreatingRoomType.publicRoom.name, description: CreatingRoomType.publicRoom.description, icon: CreatingRoomType.publicRoom.icon)
        default:
            return Room(type: CreatingRoomType.collaboration, name: CreatingRoomType.collaboration.name, description: CreatingRoomType.collaboration.description, icon: CreatingRoomType.collaboration.icon)
        }
    }
}
