//
//  NetworkManagerSharedSettings.swift
//  Documents
//
//  Created by Lolita Chernysheva on 03.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation

struct LinkModel {}

protocol NetworkManagerSharedSettingsProtocol {
    func fetchFileLinks(file: ASCFile, completion: @escaping (Result<[SharedSettingsLinkResponceModel], Error>) -> Void)
    func setLinkAccess(file: ASCFile, requestModel: EditSharedLinkRequestModel, completion: @escaping (Result<SharedSettingsLinkResponceModel, Error>) -> Void)
}

final class NetworkManagerSharedSettings: NetworkManagerSharedSettingsProtocol {
    private var networkService = OnlyofficeApiClient.shared

    func fetchFileLinks(file: ASCFile, completion: @escaping (Result<[SharedSettingsLinkResponceModel], Error>) -> Void) {
        networkService.request(OnlyofficeAPI.Endpoints.Files.getLinks(file: file)) { result, error in
            guard let links = result?.result else {
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.failure(RoomSharingNetworkService.Errors.emptyResponse))
                }
                return
            }
            completion(.success(links))
        }
    }

    func setLinkAccess(file: ASCFile, requestModel: EditSharedLinkRequestModel, completion: @escaping (Result<SharedSettingsLinkResponceModel, Error>) -> Void) {
        networkService.request(OnlyofficeAPI.Endpoints.Files.setLinkAccess(file: file), requestModel.dictionary) { result, error in
            guard let link = result?.result else {
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.failure(RoomSharingNetworkService.Errors.emptyResponse))
                }
                return
            }
            completion(.success(link))
        }
    }

    func regenerateLink(file: ASCFile, requestModel: EditSharedLinkRequestModel, completion: @escaping (Result<SharedSettingsLinkResponceModel, Error>) -> Void) {
        networkService.request(OnlyofficeAPI.Endpoints.Files.regenerateLink(file: file), requestModel.dictionary) {
            result, error in
            guard let link = result?.result else {
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.failure(RoomSharingNetworkService.Errors.emptyResponse))
                }
                return
            }
            completion(.success(link))
        }
    }

    func createAndCopy(file: ASCFile, completion: @escaping (Result<SharedSettingsLinkResponceModel, Error>) -> Void) {
        networkService.request(OnlyofficeAPI.Endpoints.Files.createAndCopyLink(file: file)) { result, error in
            guard let link = result?.result else {
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.failure(RoomSharingNetworkService.Errors.emptyResponse))
                }
                return
            }
            completion(.success(link))
        }
    }

    func addLink(file: ASCFile, requestModel: AddSharedLinkRequestModel, completion: @escaping (Result<SharedSettingsLinkResponceModel, Error>) -> Void) {
        networkService.request(OnlyofficeAPI.Endpoints.Files.addLink(file: file), requestModel.dictionary) { result, error in
            guard let link = result?.result else {
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.failure(RoomSharingNetworkService.Errors.emptyResponse))
                }
                return
            }
            completion(.success(link))
        }
    }
}

struct SharedSettingsLinkModel {
    let name: String
}
