//
//  NetworkManagerSharedSettings.swift
//  Documents-opensource
//
//  Created by Lolita Chernysheva on 03.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation

struct LinkModel {}

protocol NetworkManagerSharedSettingsProtocol {
    func fetchFileLinks(file: ASCFile, completion: @escaping (Result<[SharedSettingsLinkResponceModel], Error>) -> Void)
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
}

struct SharedSettingsLinkModel {
    let name: String
}
