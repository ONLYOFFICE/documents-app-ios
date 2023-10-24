//
//  Encodable+Extensions.swift
//  Documents
//
//  Created by Alexander Yuzhin on 17.08.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

extension Encodable {
    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
    }
}
