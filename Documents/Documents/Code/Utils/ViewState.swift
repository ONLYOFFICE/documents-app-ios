//
//  ViewState.swift
//  Documents-opensource
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
        if case .loaded(let content) = self {
            return content
        }
        return nil
    }
    
    var error: Error? {
        if case .error(let error) = self {
            return error
        }
        return nil
    }
}
