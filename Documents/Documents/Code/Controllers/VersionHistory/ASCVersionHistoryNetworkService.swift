//
//  ASCVersionHistoryNetworkService.swift
//  Documents
//
//  Created by Lolita Chernysheva on 23.04.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol ASCVersionHistoryNetworkServiceProtocol {
    func restoreVersion(file: ASCFile, versionNumber: Int, completion: @escaping (Result<ASCFile, Error>) -> Void)
    func loadData(file: ASCFile, completion: @escaping (Result<[ASCFile], Error>) -> Void)
    func deleteVersion(file: ASCFile, versionNember: Int, handler: ASCEntityProgressHandler?)
}

final class ASCVersionHistoryNetworkService: ASCVersionHistoryNetworkServiceProtocol {
    
    private var networkService = OnlyofficeApiClient.shared
    
    func restoreVersion(file: ASCFile, versionNumber: Int, completion: @escaping (Result<ASCFile, Error>) -> Void) {
        let requestModel = ASCRestoreVersionRequestModel(lastversion: versionNumber)
        networkService.request(OnlyofficeAPI.Endpoints.Files.restoreFileVersion(file: file), requestModel.dictionary) { result, error in
            guard let version = result?.result else {
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.failure(ASCVersionHistoryNetworkService.Errors.emptyResponse))
                }
                return
            }
            completion(.success(version))
        }
    }
    
    func loadData(file: ASCFile, completion: @escaping (Result<[ASCFile], Error>) -> Void) {
        networkService.request(OnlyofficeAPI.Endpoints.Files.getVersionHistory(file: file)) { result, error in
            guard let versions = result?.result else {
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.failure(ASCVersionHistoryNetworkService.Errors.emptyResponse))
                }
                return
            }
            completion(.success(versions))
            
        }
    }
    
    func deleteVersion(file: ASCFile, versionNember: Int, handler: ASCEntityProgressHandler?) {
        var cancel = false
        
        guard let fileId = Int(file.id) else { return }
        handler?(.begin, 0, nil, nil, &cancel)
        
        let requestModel = ASCDeleteVersionRequestModel(fileId: fileId, versions: [versionNember])
        
        networkService.request(OnlyofficeAPI.Endpoints.Operations.deleteVersion, requestModel.dictionary) { responce, error in
            if let error = error {
                handler?(.error, 1, nil, error, &cancel)
            } else {
                var checkOperation: (() -> Void)?
                checkOperation = {
                    self.networkService.request(OnlyofficeAPI.Endpoints.Operations.list) { result, error in
                        if let error = error {
                            handler?(.error, 1, nil, error, &cancel)
                        } else if let operation = result?.result?.first,
                                  let progress = operation.progress {
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
}

extension ASCVersionHistoryNetworkService {
    enum Errors: Error {
        case emptyResponse
    }
}
