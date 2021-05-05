//
//  ASCPasswordRecoveryController.swift
//  Documents
//
//  Created by Иван Гришечко on 04.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import Alamofire

class ASCPasswordRecoveryController {
    
    public static let shared = ASCPasswordRecoveryController()
    
    // MARK: - Public
    
    func forgotPassword(portalUrl: String, options: Parameters, completion: @escaping ((Result<ASCResponsePassword, Error>) -> Void)) {

        let api        = ASCOnlyOfficeApi.shared
        let apiRequest = ASCOnlyOfficeApi.apiForgotPassword
        
        api.baseUrl = portalUrl
        
        ASCOnlyOfficeApi.post(apiRequest, parameters: options) { (results, error, request) in
            if let results = results as? String {
                completion(.success(ASCResponsePassword(response: results)))
            }
            if let error = error {
                completion(.failure(error))
            }
        }
    }
}

