//
//  OwncloudEndpoints.swift
//  Documents-develop
//
//  Created by Victor Tihovodov on 3/11/25.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Alamofire
import Foundation

enum OwncloudEndpoints {
    enum Path {
        static let authorize: String = "/signin/v1/identifier/_/authorize"
        static let token: String = "/konnect/v1/token"
        static let currentUser: String = "/konnect/v1/userinfo"
        static let redirectURL: String = "/oidc-callback.html"
        static let callbackURL: String = "#code"
    }

    enum ClientId {
        static let web = "web"
    }

    // MARK: - Errors

    enum OIDCError: LocalizedError {
        case invalidAuthorizeURL
        case missingCode
        case stateMismatch
        case idpError(error: String, description: String?)
        case network

        var errorDescription: String? {
            switch self {
            case .invalidAuthorizeURL: return NSLocalizedString("Invalid URL", comment: "")
            case .missingCode: return NSLocalizedString("Authorization code not found", comment: "")
            case .stateMismatch: return NSLocalizedString("State is invalid", comment: "")
            case let .idpError(e, d): return "IDP error: \(e)\(d.map { " — \($0)" } ?? "")"
            case .network: return NSLocalizedString("Network error", comment: "")
            }
        }
    }
}
