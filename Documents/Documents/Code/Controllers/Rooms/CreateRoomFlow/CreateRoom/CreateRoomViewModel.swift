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

    private var networkService = OnlyofficeApiClient.shared
    
    private var tagsDispatchGroup = DispatchGroup()

    init(selectedRoom: Room) {
        self.selectedRoom = selectedRoom
    }

    func createRoom() {
        let params: [String: Any] = [
            "roomType": selectedRoom.type.id,
            "title": roomName,
        ]
        isCreatingRoom = true
        networkService.request(OnlyofficeAPI.Endpoints.Rooms.create(), params) { [weak self] response, error in
            guard let self = self else { return }
           
            guard let room = response?.result, error == nil else {
                self.errorMessage = error!.localizedDescription
                DispatchQueue.main.async {
                    self.isCreatingRoom = false
                }
                return
            }
            
            let dispatchGroup = DispatchGroup()
            
            if !tags.isEmpty {
                dispatchGroup.enter()
                createTags {
                    self.addTagsToRoom(room: room) { [weak self] in
                        guard let self else { return }
                        dispatchGroup.leave()
                    }
                }
            }
            if selectedImage != nil {
                dispatchGroup.enter()
                uploadImage(room: room) {
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) { [weak self] in
                guard let self else { return }
                self.isCreatingRoom = false
                self.dismissNavStack = true
            }
        }
    }
    
    private func createTags(completion: @escaping () -> Void) {
        for tag in tags {
            tagsDispatchGroup.enter()
            networkService.request(OnlyofficeAPI.Endpoints.Tags.create(), ["name": tag]) { [tagsDispatchGroup] _, _ in
                tagsDispatchGroup.leave()
            }
        }
        tagsDispatchGroup.notify(queue: .global()) {
            completion()
        }
    }
    
    private func addTagsToRoom(room: ASCFolder, completion: @escaping () -> Void) {
        let tags: [String] = self.tags.map { $0 }
        networkService.request(OnlyofficeAPI.Endpoints.Tags.addToRoom(folder: room), ["names": tags]) { _, _ in
            completion()
        }
    }

    func makeImageMenuItems() -> [MenuViewItem] {
        [
            .init(text: NSLocalizedString("Photo Library", comment: ""), systemImageName: "photo", action: imageFromLibraryAction),
            .init(text: NSLocalizedString("Take Photo", comment: ""), systemImageName: "camera", action: imageFromCameraAction),
            .init(text: NSLocalizedString("Choose Files", comment: ""), systemImageName: "folder", action: imageFromFilesAction),
        ]
    }
    
    private func uploadImage(room: ASCFolder, completion: @escaping () -> Void) {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.95)
        else { return }
        
        let imageWidth = Int(image.size.width)
        let imageHeight = Int(image.size.height)
        let fileName = "\(roomName).jpg"
        let mimeType = "image/jpeg"
        
        networkService.request(OnlyofficeAPI.Endpoints.Uploads.logos()) { multipartFormData in
            multipartFormData.append(imageData, withName: "file", fileName: fileName, mimeType: mimeType)
        } _: { response, progress, error in
            if let logoUpdateResult = response?.result {
                self.setImage(to: room, logo: logoUpdateResult, imageSize: CGSize(width: imageWidth, height: imageHeight), completion: completion)
            }
            if error != nil {
                completion()
            }
        }
    }

    private func setImage(to room: ASCFolder, logo: LogoUploadResult, imageSize: CGSize, completion: @escaping () -> Void) {
        guard logo.success else {
            completion()
            return
        }
        
        let params: [String: Any] = [
            "tmpFile": logo.tmpFileUrl,
            "x": 0,
            "y": 0,
            "width": imageSize.width,
            "height": imageSize.height
        ]
        
        networkService.request(OnlyofficeAPI.Endpoints.Rooms.setLogo(folder: room), params) { _, _ in
            completion()
        }
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
