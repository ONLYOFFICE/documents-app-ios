//
//  NetworkingError.swift
//  Documents
//
//  Created by Alexander Yuzhin on 29.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

enum NetworkingError: LocalizedError {
    case cancelled
    case timeOut
    case noInternet
    case invalidUrl
    case invalidData
    case statusCode(Int)
    case apiError(error: NetworkingServerError)
    case unknown(error: Error?)
    
    public var errorDescription: String? {
        switch self {
        case .cancelled:
            return NSLocalizedString("Request canceled", comment: "")
        case .timeOut:
            return NSLocalizedString("The request timed out.", comment: "")
        case .noInternet:
            return NSLocalizedString("No Internet connection", comment: "")
        case .invalidUrl:
            return NSLocalizedString("Invalid Url", comment: "")
        case .invalidData:
            return NSLocalizedString("Invalid Data", comment: "")
        case .statusCode(let code):
            return String(format: NSLocalizedString("Error code: %ld", comment: ""), code)
        case .apiError(let error):
            return error.localizedDescription
        case .unknown(let error):
            return error?.localizedDescription ?? NSLocalizedString("Unknown error", comment: "")
        }
    }
}
