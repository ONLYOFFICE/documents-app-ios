//
//  ASCDocumentSortType.swift
//  Documents
//
//  Created by Alexander Yuzhin on 27.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

typealias ASCDocumentSortStateType = (type: ASCDocumentSortType, active: Bool)

enum ASCDocumentSortType: String, CaseIterable {
    case dateandtime
    case az
    case size
    case author
    case type
    case new
    case tag
    case unknown = ""

    init() {
        self = .unknown
    }

    init(_ type: String) {
        switch type {
        case "dateandtime":
            self = .dateandtime
        case "title", "az":
            self = .az
        case "size":
            self = .size
        case "author":
            self = .author
        case "type":
            self = .type
        case "new":
            self = .new
        case "tag":
            self = .tag
        default:
            self = .unknown
        }
    }

    var description: String {
        switch self {
        case .dateandtime:
            return NSLocalizedString("Date", comment: "")
        case .az:
            return NSLocalizedString("Title", comment: "")
        case .size:
            return NSLocalizedString("Size", comment: "")
        case .author:
            return NSLocalizedString("Author", comment: "")
        case .type:
            return NSLocalizedString("Type", comment: "")
        case .new:
            return NSLocalizedString("New", comment: "")
        case .tag:
            return NSLocalizedString("Tag", comment: "")
        case .unknown:
            return ""
        }
    }

    func subtitle(for ascending: Bool) -> String {
        switch self {
        case .dateandtime:
            return ascending
                ? NSLocalizedString("From new to old", comment: "")
                : NSLocalizedString("From old to new", comment: "")

        case .az:
            return ascending
                ? NSLocalizedString("Ascending", comment: "")
                : NSLocalizedString("Descending", comment: "")

        case .size:
            return ascending
                ? NSLocalizedString("From big to small", comment: "")
                : NSLocalizedString("From small to big", comment: "")

        case .author:
            return ascending
                ? NSLocalizedString("Ascending", comment: "")
                : NSLocalizedString("Descending", comment: "")

        case .type:
            return ascending
                ? NSLocalizedString("Ascending", comment: "")
                : NSLocalizedString("Descending", comment: "")

        case .new:
            return ascending
                ? NSLocalizedString("Newer", comment: "")
                : NSLocalizedString("Older", comment: "")

        case .tag:
            return ascending
                ? NSLocalizedString("Ascending", comment: "")
                : NSLocalizedString("Descending", comment: "")

        case .unknown:
            return ascending
                ? NSLocalizedString("Ascending", comment: "")
                : NSLocalizedString("Descending", comment: "")
        }
    }
}
