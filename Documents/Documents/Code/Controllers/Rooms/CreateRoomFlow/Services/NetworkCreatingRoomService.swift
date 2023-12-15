//
//  NetworkCreatingRoomService.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 13.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol CreatingRoomService {
    func createRoom(model: CreatingRoomModel, completion: @escaping (Result<ASCFolder, Error>) -> Void)
}

struct CreatingRoomModel {
    var roomType: ASCRoomType
    var name: String
    var image: UIImage?
    var tags: [String]
}

class NetworkCreatingRoomServiceImp: CreatingRoomService {
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

    private func createRoomNetwork(model: CreatingRoomModel, completion: @escaping (Result<ASCFolder, Error>) -> Void) {
        let requestModel = CreateRoomRequestModel(roomType: model.roomType.rawValue, title: model.name)
        networkService.request(OnlyofficeAPI.Endpoints.Rooms.create(requestModel: requestModel)) { response, error in
            guard let room = response?.result, error == nil else {
                completion(.failure(error!))
                return
            }
            completion(.success(room))
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
        let group = DispatchGroup()
        for tag in tags {
            group.enter()
            let requestModel = CreateTagRequestModel(name: tag)
            networkService.request(OnlyofficeAPI.Endpoints.Tags.create(requestModel: requestModel)) { _, _ in
                group.leave()
            }
        }
        group.notify(queue: .global()) {
            completion()
        }
    }

    private func attachTagsToRoom(tags: [String], room: ASCFolder, completion: @escaping () -> Void) {
        let requestModel = AttachTagsRequestModel(names: tags)
        networkService.request(OnlyofficeAPI.Endpoints.Tags.attach(folder: room, requestModel: requestModel)) { _, _ in
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

        networkService.request(OnlyofficeAPI.Endpoints.Rooms.attachLogo(folder: room, requestModel: requestModel)) { result, _ in
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
