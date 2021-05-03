//
//  NetworkingServerError.swift
//  Documents-develop
//
//  Created by Alexander Yuzhin on 30.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

enum NetworkingServerError {
    case undefined(message: String?)
    
    init(rawValue: String) {
        switch rawValue {
        default:
            self = .undefined(message: rawValue)
        }
    }
    
    var localized: String {
        switch self {
        case .undefined(let message):
            return message ?? NSLocalizedString("Something went wrong, try again", comment: "")
        }
    }
}
