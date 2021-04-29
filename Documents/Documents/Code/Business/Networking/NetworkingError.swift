//
//  NetworkingError.swift
//  Documents-develop
//
//  Created by Alexander Yuzhin on 29.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

enum NetworkingError: Error {
    case cancelled
    case noInternet
    case invalidUrl
    case invalidData
    case invalidContext
    case statusCode(Int)
//    case apiError(message: NetworkingServerError)
}
