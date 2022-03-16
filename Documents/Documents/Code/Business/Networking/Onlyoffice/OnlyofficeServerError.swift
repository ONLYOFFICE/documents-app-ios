//
//  OnlyofficeServerError.swift
//  Documents
//
//  Created by Alexander Yuzhin on 05.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

enum OnlyofficeServerError: NetworkingServerError {
    case unauthorized
    case paymentRequired
    case forbidden
    case notFound
    case unknown(message: String?)

    init(rawValue: String) {
        switch rawValue {
        case "PaymentRequired":
            self = .paymentRequired
        case "Forbidden":
            self = .forbidden
        case "NotFound":
            self = .notFound
        default:
            self = .unknown(message: rawValue)
        }
    }

    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return NSLocalizedString("User authentication required", comment: "")
        case let .unknown(message):
            return message ?? NSLocalizedString("Something went wrong, try again", comment: "")
        case .paymentRequired:
            return ASCLocalization.Error.paymentRequiredTitle
        case .forbidden:
            return ASCLocalization.Error.forbiddenTitle
        case .notFound:
            return ASCLocalization.Error.notFoundTitle
        }
    }
}
