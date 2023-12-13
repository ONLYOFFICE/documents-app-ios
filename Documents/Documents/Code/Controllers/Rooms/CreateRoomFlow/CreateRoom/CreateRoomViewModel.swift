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
    @Published var roomName: String = ""
    @Published var isCreatingRoom = false
    @Published var errorMessage: String?
    @Published var dismissNavStack = false
    @Published var selectedRoom: Room!
    @Published var selectedImage: UIImage?
    @Published var tags: Set<String> = []
    
    lazy var menuItems: [MenuViewItem] = makeImageMenuItems()

    private lazy var creatingRoomService: CreatingRoomService = NetworkCreatingRoomServiceImp()

    init(selectedRoom: Room) {
        self.selectedRoom = selectedRoom
    }

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

    func makeImageMenuItems() -> [MenuViewItem] {
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
            guard
                let self = self,
                let url = url
            else {
                self?.errorMessage = error?.localizedDescription
                return
            }
            self.selectedImage = UIImage(contentsOfFile: url.path)
            attachManager.cleanup(for: temporaryFolderName)
        }
    }
    
    private func imageFromCameraAction() {
        let attachManager = ASCAttachmentManager()
        let temporaryFolderName = UUID().uuidString
        guard let topController = topController() else { return }
        attachManager.storeFromCamera(in: topController, to: temporaryFolderName) { [weak self] url, error in
            guard
                let self = self,
                let url = url
            else {
                self?.errorMessage = error?.localizedDescription
                return
            }
            
            self.selectedImage = UIImage(contentsOfFile: url.path)
            attachManager.cleanup(for: temporaryFolderName)
        }
    }
    
    private func imageFromFilesAction() {
        let attachManager = ASCAttachmentManager()
        let temporaryFolderName = UUID().uuidString
        guard let topController = topController() else { return }
        attachManager.storeFromFiles(in: topController, to: temporaryFolderName) { [weak self] url, error in
            guard
                let self = self,
                let url = url
            else {
                self?.errorMessage = error?.localizedDescription
                return
            }
            
            self.selectedImage = UIImage(contentsOfFile: url.path)
            attachManager.cleanup(for: temporaryFolderName)
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
