//
//  RoomTemplatesNetworkService.swift
//  Documents
//
//  Created by Lolita Chernysheva on 25.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

enum RoomCreationProgress {
    case begin
    case progress(Double)
    case success
    case failure(Error)
}

protocol ASCRoomTemplatesNetworkServiceProtocol {
    func createTemplate(room: CreateRoomTemplateModel) -> AsyncStream<RoomCreationProgress>
    func deleteRoomTemplate(template: ASCFolder) -> AsyncStream<RoomCreationProgress>
    func createRoomFromTemplate(template: CreateRoomFromTemplateModel) -> AsyncStream<RoomCreationProgress>
    func fetchTemplates() async throws -> [ASCFolder]
    func getAccessList(template: ASCFolder) async throws -> [ASCTemplateAccessModel]
    func setAccess(template: ASCFolder, invitations: [ASCRoomTemplateInviteItemRequestModel]) async throws -> OnlyofficeInviteResponseModel
    func setRoomTemplateAsPublic(templateId: Int, isPublic: Bool) async throws
    func getIsRoomTemplateAvailableForEveryone(template: ASCFolder) async throws -> Bool
}

final class ASCRoomTemplatesNetworkService: ASCRoomTemplatesNetworkServiceProtocol {
    private var networkService = OnlyofficeApiClient.shared
    
    func getIsRoomTemplateAvailableForEveryone(template: ASCFolder) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            networkService.request(OnlyofficeAPI.Endpoints.Rooms.getRoomTemplateIsPiblic(template: template)) { result, error in
                if let isPublic = result?.result {
                    continuation.resume(returning: isPublic)
                } else {
                    continuation.resume(throwing: error ?? Errors.emptyResponse)
                }
            }
            
        }
    }
    
    func setRoomTemplateAsPublic(templateId: Int, isPublic: Bool = true) async throws {
        let requestModel = ASCSetRoomTemplateAvailableForEveryoneRequestModel(id: templateId, isPublic: isPublic)
        try await withCheckedThrowingContinuation { continuation in
            networkService.request(OnlyofficeAPI.Endpoints.Rooms.setRoomTemplateAsPublic(), requestModel.toJSON()) { result, error in
                if result != nil && error == nil {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? Errors.emptyResponse)
                }
            }
        }
    }

    func setAccess(
        template: ASCFolder,
        invitations: [ASCRoomTemplateInviteItemRequestModel]
    ) async throws -> OnlyofficeInviteResponseModel {
        let requestModel = ASCRoomTemplateInviteRequestModel(
            invitations: invitations,
            notify: false,
            sharingMessage: nil
        )

        return try await withCheckedThrowingContinuation { continuation in
            networkService.request(
                OnlyofficeAPI.Endpoints.Rooms.setRoomTemplateAccess(template: template),
                requestModel.toJSON()
            ) { result, error in
                if let response = result?.result {
                    continuation.resume(returning: response)
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: Errors.emptyResponse)
                }
            }
        }
    }
    
    func getAccessList(template: ASCFolder) async throws -> [ASCTemplateAccessModel]  {
        return try await withCheckedThrowingContinuation { continuation in
            networkService.request(OnlyofficeAPI.Endpoints.Rooms.getRoomTemplateAccessList(template: template)) { result, error in
                if let accessList = result?.result {
                    continuation.resume(returning: accessList)
                } else {
                    continuation.resume(throwing: error ?? Errors.emptyResponse)
                }
            }
        }
    }

    func fetchTemplates() async throws -> [ASCFolder] {
        let params = ["searchArea": "Templates"]
        
        return try await withCheckedThrowingContinuation { continuation in
            networkService.request(OnlyofficeAPI.Endpoints.Rooms.roomTemplates(), params) { result, error in
                if let templates = result?.result?.folders {
                    continuation.resume(returning: templates)
                } else {
                    continuation.resume(throwing: error ?? Errors.emptyResponse)
                }
            }
        }
    }
    
    func deleteRoomTemplate(template: ASCFolder) -> AsyncStream<RoomCreationProgress> {
        AsyncStream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }

            let requestModel = ASCDeleteRoomTemplateRequestModel(folderIds: [template.id], fileIds: [])

            networkService.request(OnlyofficeAPI.Endpoints.Operations.removeEntities, requestModel.dictionary) { response, error in
                if let error = error {
                    continuation.yield(.failure(error))
                    continuation.finish()
                } else {
                    func checkStatus() {
                        self.networkService.request(OnlyofficeAPI.Endpoints.Operations.list) { result, error in
                            if let error = error {
                                continuation.yield(.failure(error))
                                continuation.finish()
                            } else if let operation = result?.result?.first,
                                      let progress = operation.progress {
                                if progress >= 100 {
                                    continuation.yield(.progress(1.0))
                                    continuation.yield(.success)
                                    continuation.finish()
                                } else {
                                    continuation.yield(.progress(Double(progress) / 100))
                                    Task {
                                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                                        checkStatus()
                                    }
                                }
                            } else {
                                continuation.yield(.failure(NetworkingError.invalidData))
                                continuation.finish()
                            }
                        }
                    }

                    checkStatus()
                }
            }
        }
    }
    
    func createRoomFromTemplate(template: CreateRoomFromTemplateModel) -> AsyncStream<RoomCreationProgress> {
        AsyncStream { continuation in
            var cancel = false
            continuation.yield(.begin)

            let requestModel = ASCCreateRoomFromTemplateRequestModel(
                templateId: template.templateId,
                roomType: template.roomType.rawValue,
                title: template.title,
                color: template.color,
                denyDownload: template.denyDownload,
                indexing: template.indexing,
                copyLogo: false
            )

            networkService.request(OnlyofficeAPI.Endpoints.Operations.createRoomFromTemplate, requestModel.dictionary) { response, error in
                if let error = error {
                    continuation.yield(.failure(error))
                    continuation.finish()
                    return
                }

                func checkStatus() {
                    self.networkService.request(OnlyofficeAPI.Endpoints.Operations.createRoomFromTemplateStatus) { result, error in
                        if let error = error {
                            continuation.yield(.failure(error))
                            continuation.finish()
                        } else if let status = result?.result,
                                  let progress = status.progress {
                            if progress >= 100 {
                                continuation.yield(.progress(1.0))
                                continuation.yield(.success)
                                continuation.finish()
                            } else {
                                continuation.yield(.progress(Double(progress) / 100))
                                Task {
                                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                                    checkStatus()
                                }
                            }
                        } else {
                            continuation.yield(.failure(NetworkingError.invalidData))
                            continuation.finish()
                        }
                    }
                }
                checkStatus()
            }
        }
    }
    
    func createTemplate(room: CreateRoomTemplateModel) -> AsyncStream<RoomCreationProgress> {
        AsyncStream { continuation in
            var cancel = false

            guard let roomIdString = room.roomId,
                  let roomId = Int(roomIdString) else {
                continuation.yield(.failure(Errors.invalidData))
                continuation.finish()
                return
            }

            continuation.yield(.begin)

            let requestModel = ASCCreateRoomTemplateRequestModel(
                title: room.title,
                roomId: roomId,
                tags: room.tags,
                public: room.public,
                copylogo: room.copylogo,
                color: room.color
            )

            networkService.request(OnlyofficeAPI.Endpoints.Operations.saveRoomAsTemplate, requestModel.dictionary) { response, error in
                if let error = error {
                    continuation.yield(.failure(error))
                    continuation.finish()
                } else {
                    func checkStatus() {
                        self.networkService.request(OnlyofficeAPI.Endpoints.Operations.roomTemplateStatus) { result, error in
                            if let error = error {
                                continuation.yield(.failure(error))
                                continuation.finish()
                            } else if let status = result?.result,
                                      let progress = status.progress {
                                if progress >= 100 {
                                    continuation.yield(.progress(1.0))
                                    continuation.yield(.success)
                                    continuation.finish()
                                } else {
                                    continuation.yield(.progress(Double(progress) / 100))
                                    Task {
                                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                                        checkStatus()
                                    }
                                }
                            } else {
                                continuation.yield(.failure(NetworkingError.invalidData))
                                continuation.finish()
                            }
                        }
                    }

                    checkStatus()
                }
            }
        }
    }
}

extension ASCRoomTemplatesNetworkService {
    enum Errors: Error {
        case emptyResponse
        case invalidData
    }
}

class ASCRoomTemplate: Mappable {
    var folders: [ASCFolder]?

    required convenience init?(map: Map) {
        self.init()
    }

    func mapping(map: Map) {
        folders <- map["folders"]
    }
}
