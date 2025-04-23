//
//  ASCVersionHistoryNetworkService.swift
//  Documents
//
//  Created by Lolita Chernysheva on 23.04.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//


protocol ASCVersionHistoryNetworkServiceProtocol {
    func restoreVersion(file: ASCFile, versionNumber: Int, completion: @escaping (Result<ASCFile, Error>) -> Void)
    func loadData(file: ASCFile, completion: @escaping (Result<[ASCFile], Error>) -> Void)
    
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
}

extension ASCVersionHistoryNetworkService {
    enum Errors: Error {
        case emptyResponse
    }
}
