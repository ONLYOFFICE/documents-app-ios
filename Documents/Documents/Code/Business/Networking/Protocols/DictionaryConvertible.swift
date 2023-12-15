//
//  DictionaryConvertible.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 14.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol DictionaryConvertible {
    func toDictionary() -> [String: Any]
}

extension Encodable {
    func toDictionary() -> [String: Any]? {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(self)
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            return jsonObject as? [String: Any]
        } catch {
            print("Error converting to dictionary: \(error)")
            return nil
        }
    }
}
