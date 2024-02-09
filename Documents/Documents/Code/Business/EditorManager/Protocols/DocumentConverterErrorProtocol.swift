//
//  DocumentConverterErrorProtocol.swift
//  Documents
//
//  Created by Alexander Yuzhin on 09.02.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

protocol DocumentConverterErrorProtocol: Equatable {
    var identifier: String { get }
}

extension DocumentConverterErrorProtocol {
    func isEqual(_ other: Any) -> Bool {
        if let other = other as? Self {
            return self == other
        } else if let other = other as? (any DocumentConverterErrorProtocol) {
            return identifier == other.identifier
        } else {
            return false
        }
    }
}
