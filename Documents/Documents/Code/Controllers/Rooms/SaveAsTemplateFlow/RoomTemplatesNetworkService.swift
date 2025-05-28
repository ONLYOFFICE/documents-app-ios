//
//  RoomTemplatesNetworkService.swift
//  Documents
//
//  Created by Lolita Chernysheva on 25.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol ASCRoomTemplatesNetworkServiceProtocol {
    func createTemplate(room: CreateRoomTemplateModel, handler: ASCEntityProgressHandler?)
    func deleteRoomTemplate(template: ASCFolder, handler: ASCEntityProgressHandler?)
}

final class ASCRoomTemplatesNetworkService: ASCRoomTemplatesNetworkServiceProtocol {
    private var networkService = OnlyofficeApiClient.shared
    
    func deleteRoomTemplate(template: ASCFolder, handler: ASCEntityProgressHandler?) {
        var cancel = false
        
        handler?(.begin, 0, nil, nil, &cancel)
        
        let requestModel = ASCDeleteRoomTemplateRequestModel(folderIds: [template.id], fileIds: [])
        
        networkService.request(OnlyofficeAPI.Endpoints.Operations.removeEntities, requestModel.dictionary) { responce, error in
            if let error = error {
                handler?(.error, 1, nil, error, &cancel)
            } else {
                var checkOperation: (() -> Void)?
                checkOperation = {
                    self.networkService.request(OnlyofficeAPI.Endpoints.Operations.list) { result, error in
                        if let error = error {
                            handler?(.error, 1, nil, error, &cancel)
                        } else if let operation = result?.result?.first, let progress = operation.progress {
                            if progress >= 100 {
                                handler?(.end, 1, nil, nil, &cancel)
                            } else {
                                Thread.sleep(forTimeInterval: 1)
                                checkOperation?()
                            }
                        } else {
                            handler?(.error, 1, nil, NetworkingError.invalidData, &cancel)
                        }
                    }
                }
                checkOperation?()
            }
            
        }
    }
    
    func createTemplate(room: CreateRoomTemplateModel, handler: ASCEntityProgressHandler?) {
        var cancel = false
        
        guard let roomIdString = room.roomId,
              let roomId = Int(roomIdString) else { return }
        
        handler?(.begin, 0, nil, nil, &cancel)
        
        let requestModel = ASCCreateRoomTemplateRequestModel(
            title: room.title,
            roomId: roomId,
            tags: room.tags,
            public: room.public,
            copylogo: room.copylogo,
            color: room.color
        )
        
        networkService.request(OnlyofficeAPI.Endpoints.Operations.saveRoomAsTemplate, requestModel.dictionary) { responce, error in
            if let error = error {
                handler?(.error, 1, nil, error, &cancel)
            } else {
                var checkStatus: (() -> Void)?
                checkStatus = {
                    self.networkService.request(OnlyofficeAPI.Endpoints.Operations.roomTemplateStatus) { result, error in
                        if let error = error {
                            handler?(.error, 1, nil, error, &cancel)
                        } else if let status = result?.result,
                                  let progress = status.progress
                        {
                            if progress >= 100 {
                                handler?(.end, 1, nil, nil, &cancel)
                            } else {
                                Thread.sleep(forTimeInterval: 1)
                                checkStatus?()
                            }
                        } else {
                            handler?(.error, 1, nil, NetworkingError.invalidData, &cancel)
                        }
                    }
                }
                checkStatus?()
            }
        }
    }
}

struct CreateRoomTemplateModel {
    let title: String?
    let roomId: String?
    let tags: [String]?
    let `public`: Bool?
    let copylogo: Bool?
    let color: String?
}
