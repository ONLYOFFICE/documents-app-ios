//
//  ViewState.swift
//  Documents
//
//  Created by Pavel Chernyshev on 27.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

enum ViewState<Content> {
    case idle
    case loading
    case loaded(Content)
    case error(Error)

    var content: Content? {
        if case let .loaded(content) = self {
            return content
        }
        return nil
    }

    var error: Error? {
        if case let .error(error) = self {
            return error
        }
        return nil
    }
}
