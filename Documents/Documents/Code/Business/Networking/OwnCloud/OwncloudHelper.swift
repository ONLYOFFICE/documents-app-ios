//
//  OwncloudHelper.swift
//  Documents-develop
//
//  Created by Victor Tihovodov on 10/11/25.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import CryptoKit
import Foundation

enum OwncloudHelper {
    static func randomPKCEVerifier(length: Int = 64) -> String {
        let chars = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        var result = ""
        result.reserveCapacity(length)
        for _ in 0 ..< length {
            result.append(chars.randomElement()!)
        }
        return result
    }

    static func codeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func makeURL(base: URL, addingPath path: String) -> URL? {
        var c = URLComponents()
        c.scheme = base.scheme
        c.user = base.user
        c.password = base.password
        c.host = base.host
        c.port = base.port

        var final = base.path
        let add = path.hasPrefix("/") ? String(path.dropFirst()) : path
        if !add.isEmpty {
            final += (final.hasSuffix("/") ? "" : "/") + add
        }
        c.path = final
        return c.url
    }
}
