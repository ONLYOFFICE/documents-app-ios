//
//  Data+Extension.swift
//  Documents
//
//  Created by Alexander Yuzhin on 13/03/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import Foundation

extension Data {
    /// String by encoding Data using the given encoding (if applicable).
    ///
    /// - Parameter encoding: encoding.
    /// - Returns: String by encoding Data using the given encoding (if applicable).
    func string(encoding: String.Encoding) -> String? {
        return String(data: self, encoding: encoding)
    }

    init?(base64URLEncoded string: String) {
        let base64Encoded = string
            .replacingOccurrences(of: "_", with: "/")
            .replacingOccurrences(of: "-", with: "+")
        // iOS can't handle base64 encoding without padding. Add manually
        let padLength = (4 - (base64Encoded.count % 4)) % 4
        let base64EncodedWithPadding = base64Encoded + String(repeating: "=", count: padLength)
        self.init(base64Encoded: base64EncodedWithPadding)
    }

    func base64URLEncodedString() -> String {
        // use URL safe encoding and remove padding
        return base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "=", with: "")
    }
}
