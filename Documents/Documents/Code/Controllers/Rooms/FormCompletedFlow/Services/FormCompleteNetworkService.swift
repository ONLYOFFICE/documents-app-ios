//
//  FormCompleteNetworkService.swift
//  Documents
//
//  Created by Lolita Chernysheva on 13.09.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol FormCompleteNetworkServiceProtocol {
    func copyFormLink(form: ASCFile, completion: @escaping (Result<SharedSettingsLinkResponceModel, Error>) -> Void)
}

final class FormCompleteNetworkService: FormCompleteNetworkServiceProtocol {
    private var networkService = OnlyofficeApiClient.shared

    func copyFormLink(form: ASCFile, completion: @escaping (Result<SharedSettingsLinkResponceModel, Error>) -> Void) {
        networkService.request(OnlyofficeAPI.Endpoints.Files.createAndCopyLink(file: form)) { result, error in
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
