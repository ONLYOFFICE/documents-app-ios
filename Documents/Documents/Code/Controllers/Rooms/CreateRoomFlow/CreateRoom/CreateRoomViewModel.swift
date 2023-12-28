//
//  CreateRoomViewModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 23.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation
import UIKit

class CreateRoomViewModel: ObservableObject {
    // MARK: - Published vars

    @Published var roomName: String = ""
    @Published var isCreatingRoom = false
    @Published var errorMessage: String?
    @Published var selectedRoom: Room!
    @Published var selectedImage: UIImage?
    @Published var tags: Set<String> = []

    // MARK: - Public vars

    lazy var menuItems: [MenuViewItem] = makeImageMenuItems()

    // MARK: - Private var

    private lazy var creatingRoomService = ServicesProvider.shared.roomCreateService
    private var onCreate: (ASCFolder) -> Void

    // MARK: - Init

    init(selectedRoom: Room, onCreate: @escaping (ASCFolder) -> Void) {
        self.selectedRoom = selectedRoom
        self.onCreate = onCreate
    }

    // MARK: - Public func

    func createRoom() {
        isCreatingRoom = true
        creatingRoomService.createRoom(
            model: .init(
                roomType: selectedRoom.type.ascRoomType,
                name: roomName,
                image: selectedImage,
                tags: tags.map { $0 }
            )
        ) { [weak self] result in
            switch result {
            case let .success(room):
                self?.onCreate(room)
            case let .failure(error):
                self?.errorMessage = error.localizedDescription
            }
            self?.isCreatingRoom = false
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
}
