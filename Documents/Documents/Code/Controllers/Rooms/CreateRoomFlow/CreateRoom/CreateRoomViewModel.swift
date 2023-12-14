//
//  CreateRoomViewModel.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 23.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation
import Combine
import UIKit

class CreateRoomViewModel: ObservableObject {
    
    // MARK: - Published vars
    
    @Published var roomName: String = ""
    @Published var isCreatingRoom = false
    @Published var errorMessage: String?
    @Published var dismissNavStack = false
    @Published var selectedRoom: Room!
    @Published var selectedImage: UIImage?
    @Published var tags: Set<String> = []
    
    // MARK: - Public vars
    
    lazy var menuItems: [MenuViewItem] = makeImageMenuItems()
    
    // MARK: - Private var

    private lazy var creatingRoomService: CreatingRoomService = NetworkCreatingRoomServiceImp()
    
    // MARK: - Init

    init(selectedRoom: Room) {
        self.selectedRoom = selectedRoom
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
        ) { [weak self] error in
            if let error {
                self?.errorMessage = error.localizedDescription
            } else {
                self?.dismissNavStack = true
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
        attachManager.storeFromLibrary(in: topController, to: temporaryFolderName) { [weak self] url, error in
            self?.handleImageSelection(url, error)
            attachManager.cleanup(for: temporaryFolderName)
        }
    }
    
    private func imageFromCameraAction() {
        let attachManager = ASCAttachmentManager()
        let temporaryFolderName = UUID().uuidString
        guard let topController = topController() else { return }
        attachManager.storeFromCamera(in: topController, to: temporaryFolderName) { [weak self] url, error in
            self?.handleImageSelection(url, error)
            attachManager.cleanup(for: temporaryFolderName)
        }
    }
    
    private func imageFromFilesAction() {
        let attachManager = ASCAttachmentManager()
        let temporaryFolderName = UUID().uuidString
        guard let topController = topController() else { return }
        attachManager.storeFromFiles(in: topController, to: temporaryFolderName) { [weak self] url, error in
            self?.handleImageSelection(url, error)
            attachManager.cleanup(for: temporaryFolderName)
        }
    }
    
    private func handleImageSelection(_ url: URL?, _ error: Error?) {
        guard let url = url else {
            errorMessage = error?.localizedDescription
            return
        }
        selectedImage = UIImage(contentsOfFile: url.path)
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
