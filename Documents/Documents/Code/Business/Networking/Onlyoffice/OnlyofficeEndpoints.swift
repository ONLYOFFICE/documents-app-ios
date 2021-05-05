//
//  OnlyofficeEndpoints.swift
//  Documents
//
//  Created by Alexander Yuzhin on 03.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import Alamofire

class OnlyofficeAPI {

    struct Path {
        // Api version
        static private let version = "2.0"
        
        // Api paths
        static public let authentication         = "api/\(version)/authentication"
        static public let authenticationPhone    = "api/\(version)/authentication/setphone"
        static public let authenticationCode     = "api/\(version)/authentication/sendsms"
        static public let serversVersion         = "api/\(version)/settings/version/build"
        static public let capabilities           = "api/\(version)/capabilities"
        static public let deviceRegistration     = "api/\(version)/portal/mobile/registration"
    }

    struct Endpoints {
        struct Auth {
            static func authentication(with code: String? = nil) -> Endpoint<OnlyofficeDataResult<OnlyofficeAuth>> {
                var path = Path.authentication
                
                if let code = code {
                    path = "\(Path.authentication)/\(code)"
                }
                
                return Endpoint<OnlyofficeDataResult<OnlyofficeAuth>>.make(path, .post)
            }
            static let deviceRegistration: Endpoint<Parameters> = Endpoint<Parameters>.make(Path.deviceRegistration, .post)
            static let sendCode: Endpoint<Parameters> = Endpoint<Parameters>.make(Path.authenticationCode, .post)
            static let sendPhone: Endpoint<Parameters> = Endpoint<Parameters>.make(Path.authenticationPhone, .post)
        }
        static let serversVersion: Endpoint<OnlyofficeDataResult<OnlyofficeVersion>> = Endpoint<OnlyofficeDataResult<OnlyofficeVersion>>.make(Path.serversVersion)
        static let serverCapabilities: Endpoint<OnlyofficeDataResult<OnlyofficeCapabilities>> = Endpoint<OnlyofficeDataResult<OnlyofficeCapabilities>>.make(Path.capabilities)
    }

}
