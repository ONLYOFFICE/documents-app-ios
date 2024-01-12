//
//  NetworkEditRoomServiceImp.swift
//  Documents
//
//  Created by Victor Tihovodov on 11.01.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation
import Kingfisher
import UIKit

struct editRoomModel {
    var roomType: ASCRoomType
    var name: String
    var image: UIImage?
    var tags: [String]
    var deletedTags: [String]
}

class NetworkEditRoomServiceImp {
    private var networkService = OnlyofficeApiClient.shared
    var icon: ASCFolderLogoAvatarView = ASCFolderLogoAvatarView(frame: CGRect(origin: CGPointMake(0, 0), size: CGSizeMake(64, 64)))

    func editRoom(model: editRoomModel, folder: ASCFolder, completion: @escaping (Result<ASCFolder, Error>) -> Void) {
        let requestModel = CreateRoomRequestModel(roomType: model.roomType.rawValue, title: model.name)

        networkService.request(OnlyofficeAPI.Endpoints.Rooms.update(folder: folder), requestModel.dictionary) { response, error in
            guard let room = response?.result, error == nil else {
                completion(.failure(error!))
                return
            }
            let group = DispatchGroup()
            group.enter()
            self.editAndAttachTags(tags: model.tags, deletedTags: model.deletedTags, room: room) {
                group.leave()
            }
            group.enter()
            self.uploadAndAttachImage(image: model.image, room: room) {
                group.leave()
            }
            group.notify(queue: .main) {
                completion(.success(room))
            }
            completion(.success(room))
        }
    }

    private func editAndAttachTags(tags: [String], deletedTags: [String], room: ASCFolder, completion: @escaping () -> Void) {
        let group = DispatchGroup()
        group.enter()
        editTags(tags: tags, deletedTags: deletedTags) {
            self.attachTagsToRoom(tags: tags, deletedTags: deletedTags, room: room) {
                group.leave()
            }
        }
        group.notify(queue: .main) {
            completion()
        }
    }

    private func editTags(tags: [String], deletedTags: [String], completion: @escaping () -> Void) {
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

    private func attachTagsToRoom(tags: [String], deletedTags: [String], room: ASCFolder, completion: @escaping () -> Void) {
        let requestAddTagsModel = AttachTagsRequestModel(names: tags)
        let requestDeleteTagsModel = AttachTagsRequestModel(names: deletedTags)
        networkService.request(OnlyofficeAPI.Endpoints.Tags.addToRoom(folder: room), requestAddTagsModel.dictionary) { _, _ in
            self.networkService.request(OnlyofficeAPI.Endpoints.Tags.deleteFromRoom(folder: room), requestDeleteTagsModel.dictionary) { _, _ in
                completion()
            }
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

    func getRoomIcon(folder: ASCFolder, completion: @escaping () -> Void) {
        icon.kf.setImage(
            with: OnlyofficeApiClient.absoluteUrl(from: URL(string: folder.logo?.large ?? "")),
            placeholder: nil,
            options: [],
            completionHandler: { result in
                switch result {
                case .success:
                    print("success")
                    completion()
                case .failure:
                    print("failed")
                    completion()
                }
            }
        )
    }
}
