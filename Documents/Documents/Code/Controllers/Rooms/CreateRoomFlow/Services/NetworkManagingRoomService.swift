//
//  NetworkManagingRoomService.swift
//  Documents
//
//  Created by Pavel Chernyshev on 13.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ManagingRoomService {
    func createRoom(model: CreatingRoomModel, completion: @escaping (Result<ASCFolder, Error>) -> Void)
    func editRoom(model: EditRoomModel, completion: @escaping (Result<ASCFolder, Error>) -> Void)
}

struct CreatingRoomModel {
    var roomType: ASCRoomType
    var name: String
    var image: UIImage?
    var tags: [String]
    var createAsNewFolder: Bool = false
    var thirdPartyFolderId: String?
}

struct EditRoomModel {
    var roomType: ASCRoomType
    var room: ASCRoom
    var name: String
    var image: UIImage?
    var ownerToChange: ASCUser?
    var tagsToAdd: [String]
    var tagsToDelete: [String]
}

class NetworkManagingRoomServiceImp: ManagingRoomService {
    private var networkService = OnlyofficeApiClient.shared

    func createRoom(model: CreatingRoomModel, completion: @escaping (Result<ASCFolder, Error>) -> Void) {
        createRoomNetwork(model: model) { result in
            switch result {
            case let .success(room):
                let group = DispatchGroup()
                group.enter()
                self.createAndAttachTags(tags: model.tags, room: room) {
                    group.leave()
                }
                group.enter()
                self.uploadAndAttachImage(image: model.image, room: room) {
                    group.leave()
                }
                group.notify(queue: .main) {
                    completion(.success(room))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Edit

extension NetworkManagingRoomServiceImp {
    func editRoom(model: EditRoomModel, completion: @escaping (Result<ASCFolder, Error>) -> Void) {
        updateRoom(room: model.room, name: model.name, roomType: model.roomType.rawValue) { [self] result in
            switch result {
            case let .success(room):
                let group = DispatchGroup()
                group.enter()
                self.editAndAttachTags(tagsToAdd: model.tagsToAdd, tagsToDelete: model.tagsToDelete, room: room) {
                    group.leave()
                }
                group.enter()
                self.uploadAndAttachImage(image: model.image, room: room) {
                    group.leave()
                }
                group.enter()
                self.changeOwner(newOwner: model.ownerToChange, room: room) {
                    group.leave()
                }
                group.notify(queue: .main) {
                    completion(.success(room))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    private func updateRoom(room: ASCRoom, name: String, roomType: Int, completion: @escaping (Result<ASCRoom, Error>) -> Void) {
        guard room.title != name else {
            completion(.success(room))
            return
        }
        let requestModel = CreateRoomRequestModel(roomType: roomType, title: name, createAsNewFolder: false)
        networkService.request(
            OnlyofficeAPI.Endpoints.Rooms.update(folder: room),
            requestModel.dictionary
        ) { response, error in
            guard let room = response?.result else {
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.failure(CreatingRoomServiceError.unableGetImageData))
                }
                return
            }
            completion(.success(room))
        }
    }

    private func editAndAttachTags(tagsToAdd: [String], tagsToDelete: [String], room: ASCFolder, completion: @escaping () -> Void) {
        guard !tagsToAdd.isEmpty || !tagsToDelete.isEmpty else {
            completion()
            return
        }

        let group = DispatchGroup()

        group.enter()
        removeTags(tags: tagsToDelete, room: room) {
            group.leave()
        }

        group.enter()
        createTags(tags: tagsToAdd) {
            self.attachTagsToRoom(tags: tagsToAdd, room: room) {
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion()
        }
    }

    private func removeTags(tags: [String], room: ASCFolder, completion: @escaping () -> Void) {
        guard !tags.isEmpty else {
            completion()
            return
        }
        let requestDeleteTagsModel = AttachTagsRequestModel(names: tags)
        networkService.request(OnlyofficeAPI.Endpoints.Tags.deleteFromRoom(folder: room), requestDeleteTagsModel.dictionary) { _, _ in
            completion()
        }
    }

    private func changeOwner(newOwner: ASCUser?, room: ASCRoom, completion: @escaping () -> Void) {
        guard let userId = newOwner?.userId else {
            completion()
            return
        }
        let requestModel = ChangeRoomOwnerRequestModel(userId: userId, folderIds: [room.id])
        networkService.request(OnlyofficeAPI.Endpoints.Sharing.changeOwner(), requestModel.dictionary) { _, error in
            if error == nil {
                room.createdBy = newOwner
            }
            completion()
        }
    }
}

// MARK: - Create

extension NetworkManagingRoomServiceImp {
    
    private func createRoomNetwork(model: CreatingRoomModel, completion: @escaping (Result<ASCFolder, Error>) -> Void) {
        let requestModel = CreateRoomRequestModel(
            roomType: model.roomType.rawValue,
            title: model.name,
            createAsNewFolder: model.createAsNewFolder
        )
        if let thirdPartyFolderId = model.thirdPartyFolderId {
            networkService.request(
                OnlyofficeAPI.Endpoints.Rooms.createThirdparty(providerId: thirdPartyFolderId),
                requestModel.dictionary
            ) { response, error in
                guard let room = response?.result, error == nil else {
                    completion(.failure(error!))
                    return
                }
                completion(.success(room))
            }
        } else {
            networkService.request(OnlyofficeAPI.Endpoints.Rooms.create(), requestModel.dictionary) { response, error in
                guard let room = response?.result, error == nil else {
                    completion(.failure(error!))
                    return
                }
                completion(.success(room))
            }
        }
    }

    private func createAndAttachTags(tags: [String], room: ASCFolder, completion: @escaping () -> Void) {
        guard !tags.isEmpty else {
            completion()
            return
        }
        let group = DispatchGroup()
        group.enter()
        createTags(tags: tags) {
            self.attachTagsToRoom(tags: tags, room: room) {
                group.leave()
            }
        }
        group.notify(queue: .main) {
            completion()
        }
    }

    private func createTags(tags: [String], completion: @escaping () -> Void) {
        guard !tags.isEmpty else {
            completion()
            return
        }
        let group = DispatchGroup()
        for tag in tags {
            group.enter()
            let requestModel = CreateTagRequestModel(name: tag)
            networkService.request(OnlyofficeAPI.Endpoints.Tags.create(), requestModel.dictionary) { _, _ in
                group.leave()
            }
        }
        group.notify(queue: .global()) {
            completion()
        }
    }

    private func attachTagsToRoom(tags: [String], room: ASCFolder, completion: @escaping () -> Void) {
        guard !tags.isEmpty else {
            completion()
            return
        }
        let requestModel = AttachTagsRequestModel(names: tags)
        networkService.request(OnlyofficeAPI.Endpoints.Tags.addToRoom(folder: room), requestModel.dictionary) { _, _ in
            completion()
        }
    }

    private func uploadAndAttachImage(image: UIImage?, room: ASCFolder, completion: @escaping () -> Void) {
        guard let image else {
            completion()
            return
        }
        uploadImage(image: image, room: room) { result in
            switch result {
            case let .success(logoUploadResult):
                let imageWidth = Int(image.size.width)
                let imageHeight = Int(image.size.height)
                self.attachImage(to: room,
                                 logo: logoUploadResult,
                                 imageSize: CGSize(width: imageWidth, height: imageHeight),
                                 completion: completion)
            case .failure:
                completion()
            }
        }
    }

    private func uploadImage(image: UIImage, room: ASCFolder, completion: @escaping (Result<LogoUploadResult, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(.failure(CreatingRoomServiceError.unableGetImageData))
            return
        }

        let fileName = "\(room.title).jpg"
        let mimeType = "image/jpeg"

        networkService.request(OnlyofficeAPI.Endpoints.Uploads.logos()) { multipartFormData in
            multipartFormData.append(imageData, withName: "file", fileName: fileName, mimeType: mimeType)
        } _: { response, progress, error in
            if let logoUpdateResult = response?.result {
                completion(.success(logoUpdateResult))
            }
            if let error {
                completion(.failure(error))
            }
        }
    }

    private func attachImage(to room: ASCFolder, logo: LogoUploadResult, imageSize: CGSize, completion: @escaping () -> Void) {
        guard logo.success else {
            completion()
            return
        }
        let requestModel = AttachLogoRequestModel(tmpFile: logo.tmpFileUrl, width: imageSize.width, height: imageSize.height)

        networkService.request(OnlyofficeAPI.Endpoints.Rooms.setLogo(folder: room), requestModel.dictionary) { result, _ in
            if let folder = result?.result {
                room.logo = folder.logo
            }
            completion()
        }
    }
}

enum CreatingRoomServiceError: Error {
    case unableGetImageData
}
