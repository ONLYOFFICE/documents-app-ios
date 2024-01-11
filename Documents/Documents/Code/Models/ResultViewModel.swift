//
//  ResultViewModel.swift
//  Documents
//
//  Created by Alexander Yuzhin on 10.01.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation

struct ResultViewModel {
    enum Result {
        case success, failure
    }

    var result: Result
    var message: String
    var hideAfter: TimeInterval = 2.5
}
