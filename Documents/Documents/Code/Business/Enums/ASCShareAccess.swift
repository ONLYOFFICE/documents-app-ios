//
//  ASCShareAccess.swift
//  Documents
//
//  Created by Alexander Yuzhin on 16/04/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import UIKit

enum ASCShareAccess: Int, CaseIterable {
    case none   = 0
    case full   = 1
    case review = 2
    case varies = 3
    case read   = 4
    case deny   = 5

    init() {
        self = .none
    }

    init(_ type: Int) {
        switch type {
        case 1: self = .full
        case 2: self = .review
        case 3: self = .varies
        case 4: self = .read
        case 5: self = .deny
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
    
    func image() -> UIImage? {
        if #available(iOS 13, *) {
            switch self {
            case .none:
                return nil
            case .full:
                return UIImage(systemName: "doc.plaintext") // MARK: - TODO change
            case .read:
                return UIImage(systemName: "eye")
            case .deny:
                return UIImage(systemName: "eye.slash")
            case .varies:
                return UIImage(systemName: "text.bubble")
            case .review:
                return UIImage(systemName: "text.bubble")
            }
        }
        return nil
    }
}
