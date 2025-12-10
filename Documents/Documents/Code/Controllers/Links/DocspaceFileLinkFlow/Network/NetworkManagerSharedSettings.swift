//
//  NetworkManagerSharedSettings.swift
//  Documents
//
//  Created by Lolita Chernysheva on 03.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Alamofire
import Foundation

struct LinkModel {}

protocol NetworkManagerSharedSettingsProtocol {
    func fetchFileLinks(file: ASCFile, completion: @escaping (Result<[SharedSettingsLinkResponceModel], Error>) -> Void)
    func setLinkAccess(file: ASCFile, requestModel: EditSharedLinkRequestModel, completion: @escaping (Result<SharedSettingsLinkResponceModel, Error>) -> Void)
    func customFilter(file: ASCFile, requestModel: ASCCustomFilterRequestModel, completion: @escaping (Result<ASCFile, Error>) -> Void)
    func createAndCopy(file: ASCFile, requestModel: CreateAndCopyLinkRequestModel?) async throws -> SharedSettingsLinkResponceModel
}

final class NetworkManagerSharedSettings: NetworkManagerSharedSettingsProtocol {
    private var networkService = OnlyofficeApiClient.shared

    func fetchFileLinks(file: ASCFile, completion: @escaping (Result<[SharedSettingsLinkResponceModel], Error>) -> Void) {
        networkService.request(OnlyofficeAPI.Endpoints.Files.getLinksShort(file: file)) { result, error in
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

    func customFilter(file: ASCFile, requestModel: ASCCustomFilterRequestModel, completion: @escaping (Result<ASCFile, Error>) -> Void) {
        networkService.request(OnlyofficeAPI.Endpoints.Files.customFilter(file: file), requestModel.dictionary) { result, error in
            guard let file = result?.result else {
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.failure(RoomSharingNetworkService.Errors.emptyResponse))
                }
                return
            }
            completion(.success(file))
        }
    }

    func createAndCopy(file: ASCFile, requestModel: CreateAndCopyLinkRequestModel?) async throws -> SharedSettingsLinkResponceModel {
        var method: HTTPMethod = .post
        var request: Dictionary? = requestModel?.dictionary
        if let docspaceVersion = networkService.serverVersion?.docSpace, docspaceVersion.isVersion(lessThan: "3.0.0") {
            method = .get
            request = nil
        }

        let response = try await networkService.request(
            endpoint: OnlyofficeAPI.Endpoints.Files.createAndCopyLink(file: file, method: method),
            parameters: request
        )

        guard let model = response.result else {
            throw NetworkingError.invalidData
        }

        return model
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
