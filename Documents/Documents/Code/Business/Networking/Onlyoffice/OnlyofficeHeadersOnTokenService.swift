//
//  OnlyofficeHeadersOnTokenService.swift
//  Documents
//
//  Created by Pavel Chernyshev on 07.02.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Alamofire

final class OnlyofficeHeadersOnTokenService: @unchecked Sendable {
    private let lockQueue = DispatchQueue(label: "OnlyofficeHeadersOnTokenService.lockQueue")

    private var headers: [String: [HTTPHeader]] = [:]

    func add(header: HTTPHeader, for token: String) {
        lockQueue.sync {
            if headers[token] == nil {
                headers[token] = []
            }
            headers[token]?.append(header)
        }
    }

    func headers(for token: String) -> [HTTPHeader] {
        lockQueue.sync {
            headers[token] ?? []
        }
    }
}
