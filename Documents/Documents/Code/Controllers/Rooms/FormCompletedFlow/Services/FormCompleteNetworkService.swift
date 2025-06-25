//
//  FormCompleteNetworkService.swift
//  Documents
//
//  Created by Lolita Chernysheva on 13.09.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Alamofire
import Foundation

protocol FormCompleteNetworkServiceProtocol {
    func copyFormLink(form: ASCFile, completion: @escaping (Result<SharedSettingsLinkResponceModel, Error>) -> Void)
}

final class FormCompleteNetworkService: FormCompleteNetworkServiceProtocol {
    private var networkService = OnlyofficeApiClient.shared

    func copyFormLink(form: ASCFile, completion: @escaping (Result<SharedSettingsLinkResponceModel, Error>) -> Void) {
        let requestModel = CreateAndCopyLinkRequestModel(access: ASCShareAccess.read.rawValue, expirationDate: nil, isInternal: false)

        var method: HTTPMethod = .post
        var request: Dictionary? = requestModel.dictionary
        if let docspaceVersion = networkService.serverVersion?.docSpace, docspaceVersion.isVersion(lessThan: "3.0.0") {
            method = .get
            request = nil
        }

        networkService.request(OnlyofficeAPI.Endpoints.Files.createAndCopyLink(file: form, method: method), request) { result, error in
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
