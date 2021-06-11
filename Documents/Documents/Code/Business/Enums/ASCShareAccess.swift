//
//  ASCShareAccess.swift
//  Documents
//
//  Created by Alexander Yuzhin on 16/04/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import Foundation

enum ASCShareAccess: Int, CaseIterable {
    case none   = 0
    case full   = 1
    case read   = 2
    case deny   = 3
    case varies = 4
    case review = 5

    init() {
        self = .none
    }

    init(_ type: Int) {
        switch type {
        case 1: self = .full
        case 2: self = .read
        case 3: self = .deny
        case 4: self = .varies
        case 5: self = .review
        default: self = .none
        }
    }
    
    func title() -> String {
        switch self {
        case .none:
            return NSLocalizedString("None", comment: "Share status")
        case .full:
            return NSLocalizedString("Full Access", comment: "Share status")
        case .read:
            return NSLocalizedString("Read Only", comment: "Share status")
        case .deny:
            return NSLocalizedString("Deny Access", comment: "Share status")
        case .varies:
            return NSLocalizedString("Varies", comment: "Share status")
        case .review:
            return NSLocalizedString("Review", comment: "Share status")
        }
    }
}
