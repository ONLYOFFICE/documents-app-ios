//
//  Decodable+Extensions.swift
//  Documents-develop
//
//  Created by Alexander Yuzhin on 17.08.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

public extension Decodable {
    /// Parsing the model in Decodable type.
    /// - Parameters:
    ///   - data: Data.
    ///   - decoder: JSONDecoder. Initialized by default.
    init?(from data: Data, using decoder: JSONDecoder = .init()) {
        guard let parsed = try? decoder.decode(Self.self, from: data) else { return nil }
        self = parsed
    }
}
