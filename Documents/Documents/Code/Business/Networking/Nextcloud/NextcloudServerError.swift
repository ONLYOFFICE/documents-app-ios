//
//  NextcloudServerError.swift
//  Documents
//
//  Created by Alexander Yuzhin on 05.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

enum NextcloudServerError: NetworkingServerError {
    case undefined(message: String?)

    init(rawValue: String) {
        switch rawValue {
        default:
            self = .undefined(message: rawValue)
        }
    }

    public var errorDescription: String? {
        switch self {
        case let .undefined(message):
            return message ?? NSLocalizedString("Something went wrong, try again", comment: "")
        }
    }
}
