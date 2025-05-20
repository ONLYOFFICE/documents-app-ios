//
//  OnlyofficeSearchArea.swift
//  Documents
//
//  Created by Alexander Yuzhin on 19.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

enum OnlyofficeSearchArea: String {
    case active
    case archive
    case any
    case recentByLinks
    case templates

    var rawValue: String {
        switch self {
        case .active:
            return "Active"

        case .archive:
            return "Archive"

        case .any:
            return "Any"

        case .recentByLinks:
            return "RecentByLinks"

        case .templates:
            return "Templates"
        }
    }
}
