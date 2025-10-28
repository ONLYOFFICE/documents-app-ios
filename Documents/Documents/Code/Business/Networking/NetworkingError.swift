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
    case sessionDeinitialized
    case statusCode(Int)
    case apiError(error: NetworkingServerError)
    case unknown(error: Error?)

    var errorDescription: String? {
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
        case .sessionDeinitialized:
            return NSLocalizedString("Connection deinitialized", comment: "")
        case let .statusCode(code):
            return String(format: NSLocalizedString("Error code: %ld", comment: ""), code)
        case let .apiError(error):
            return error.localizedDescription
        case let .unknown(error):
            return error?.localizedDescription ?? NSLocalizedString("Unknown error", comment: "")
        }
    }
}
