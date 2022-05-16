//
//  ASCTextStyle.swift
//  Documents
//
//  Created by Alexander Yuzhin on 23.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

enum ASCTextStyle {
    // MARK: - Buttons

    case title1
    case largeTitleBold

    case title3Bold

    case body
    case bodyWhite
    case semibodyWhite

    case subheadLight
    case subhead
    case subheadWhite
    case subheadBold
    case placeholderRegular

    case underlineField
    case underlinePlaceholderField

    // MARK: - signature

    case undefined

    var style: (font: UIFont, color: UIColor, lineHeightMultiple: CGFloat) {
        switch self {
        // MARK: - Buttons

        case .title1:
            if #available(iOS 13.0, *) {
                return (UIFont.preferredFont(forTextStyle: .title1), .label, 1)
            } else {
                return (UIFont.preferredFont(forTextStyle: .title1), .black, 1)
            }

        case .body:
            if #available(iOS 13.0, *) {
                return (UIFont.preferredFont(forTextStyle: .body), .label, 1)
            } else {
                return (UIFont.preferredFont(forTextStyle: .body), .black, 1)
            }

        case .bodyWhite:
            return (UIFont.preferredFont(forTextStyle: .body), .white, 1)

        case .semibodyWhite:
            return (UIFont.preferredFont(forTextStyle: .body).with(weight: .semibold), .white, 1)

        case .subhead:
            if #available(iOS 13.0, *) {
                return (UIFont.preferredFont(forTextStyle: .subheadline), .label, 1)
            } else {
                return (UIFont.preferredFont(forTextStyle: .subheadline), .black, 1)
            }

        case .subheadLight:
            if #available(iOS 13.0, *) {
                return (UIFont.preferredFont(forTextStyle: .subheadline), .secondaryLabel, 1)
            } else {
                return (UIFont.preferredFont(forTextStyle: .subheadline), .lightGray, 1)
            }

        case .subheadWhite:
            return (UIFont.preferredFont(forTextStyle: .subheadline), .white, 1)

        case .subheadBold:
            if #available(iOS 13.0, *) {
                return (UIFont.preferredFont(forTextStyle: .subheadline).bold(), .label, 1)
            } else {
                return (UIFont.preferredFont(forTextStyle: .subheadline).bold(), .black, 1)
            }

        case .title3Bold:
            if #available(iOS 13.0, *) {
                return (UIFont.preferredFont(forTextStyle: .title3).bold(), .label, 1)
            } else {
                return (UIFont.preferredFont(forTextStyle: .title3).bold(), .black, 1)
            }

        case .largeTitleBold:
            if #available(iOS 13.0, *) {
                return (UIFont.systemFont(ofSize: 34).bold(), .label, 1)
            } else {
                return (UIFont.systemFont(ofSize: 34).bold(), .black, 1)
            }

        case .placeholderRegular:
            if #available(iOS 13.0, *) {
                return (UIFont.preferredFont(forTextStyle: .footnote), .placeholderText, 1)
            } else {
                return (UIFont.preferredFont(forTextStyle: .footnote), .lightGray, 1)
            }

        case .underlineField:
            if #available(iOS 13.0, *) {
                return (UIFont.systemFont(ofSize: 14), .label, 1)
            } else {
                return (UIFont.systemFont(ofSize: 14), .black, 1)
            }

        case .underlinePlaceholderField:
            return (UIFont.systemFont(ofSize: 12), .lightGray, 1)

        // MARK: - signature

        case .undefined:
            return (UIFont(), .clear, 1.0)
        }
    }

    var font: UIFont {
        return style.font
    }

    var color: UIColor {
        return style.color
    }

    var lineHeightMultiple: CGFloat {
        return style.lineHeightMultiple
    }
}
