//
//  ASCShareAccess.swift
//  Documents
//
//  Created by Alexander Yuzhin on 16/04/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import SwiftUI
import UIKit

enum ASCShareLinkType: Int, Codable {
    case invitation = 0
    case external
}

enum ASCShareAccess: Int, CaseIterable {
    case none = 0
    case full = 1
    case read = 2
    case deny = 3
    case varies = 4
    case review = 5
    case comment = 6
    case fillForms = 7
    case userFilter = 8
    case roomManager = 9
    case editing = 10
    case contentCreator = 11

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
        case 6: self = .comment
        case 7: self = .fillForms
        case 8: self = .userFilter
        case 9: self = .roomManager
        case 10: self = .editing
        case 11: self = .contentCreator
        default: self = .none
        }
    }

    func getSortWeight() -> Int {
        switch self {
        case .none: return 5
        case .roomManager: return 7
        case .contentCreator: return 8
        case .editing: return 9
        case .full: return 10
        case .varies: return 20
        case .review: return 30
        case .comment: return 40
        case .read: return 50
        case .fillForms: return 60
        case .userFilter: return 70
        case .deny: return 80
        }
    }

    func title() -> String {
        switch self {
        case .none:
            return NSLocalizedString("None", comment: "Share status")
        case .full:
            return NSLocalizedString("Full Access", comment: "Share status")
        case .read:
            return NSLocalizedString("Viewer", comment: "Share status")
        case .deny:
            return NSLocalizedString("Deny Access", comment: "Share status")
        case .varies:
            return NSLocalizedString("Varies", comment: "Share status")
        case .review:
            return NSLocalizedString("Reviewer", comment: "Share status")
        case .comment:
            return NSLocalizedString("Commentator", comment: "Share status")
        case .fillForms:
            return NSLocalizedString("Form Filler", comment: "Share status")
        case .userFilter:
            return NSLocalizedString("Custom filter", comment: "Share status")
        case .roomManager:
            return NSLocalizedString("Room manager", comment: "Share status")
        case .editing:
            return NSLocalizedString("Editor", comment: "Share status")
        case .contentCreator:
            return NSLocalizedString("Content creator", comment: "Share status")
        }
    }

    func image() -> UIImage? {
        imageAsset?.image
    }

    var swiftUIImage: Image? {
        imageAsset?.swiftUIImage
    }

    private var imageAsset: ImageAsset? {
        if #available(iOS 13, *) {
            switch self {
            case .none:
                return nil
            case .full:
                return Asset.Images.menuFullAccess
            case .read:
                return Asset.Images.menuViewOnly
            case .deny:
                return Asset.Images.menuDenyAccess
            case .varies:

                return nil // MARK: - TODO
            case .review:
                return Asset.Images.menuReview
            case .comment:
                return Asset.Images.menuComment
            case .fillForms:
                return Asset.Images.menuFormFilling
            case .userFilter:
                return Asset.Images.menuCustomFilter
            case .roomManager:
                return Asset.Images.menuPerson
            case .editing:
                return Asset.Images.menuFullAccess
            case .contentCreator:
                return Asset.Images.menuPersonStar
            }
        }
        return nil
    }
}

extension ASCShareAccess: Codable {}
