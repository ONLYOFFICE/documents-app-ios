//
//  ASCPasswordRecoveryController.swift
//  Documents
//
//  Created by Ivan Grishechko on 04.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Alamofire
import Foundation

class ASCPasswordRecoveryController {
    static let shared = ASCPasswordRecoveryController()

    // MARK: - Public

    func forgotPassword(portalUrl: String, options: Parameters, completion: @escaping ((Result<ASCResponsePassword, Error>) -> Void)) {
        let networkClient = OnlyofficeApiClient()

        networkClient.configure(url: portalUrl)
        networkClient.request(OnlyofficeAPI.Endpoints.Settings.forgotPassword, options) { response, error in
            if let result = response?.result {
                completion(.success(ASCResponsePassword(response: result)))
            }
            if let error = error {
                completion(.failure(error))
            }
        }
    }
}
