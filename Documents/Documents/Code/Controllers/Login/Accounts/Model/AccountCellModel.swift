//
//  AccountCellModel.swift
//  Documents-opensource
//
//  Created by Lolita Chernysheva on 03.04.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import UIKit

struct AccountCellModel {
    struct Style {
        let nameFont: UIFont
        let portalFont: UIFont

        init(nameFont: UIFont = UIFont.preferredFont(forTextStyle: .body),
             portalFont: UIFont = UIFont.preferredFont(forTextStyle: .footnote))
        {
            self.nameFont = nameFont
            self.portalFont = portalFont
        }
    }

    let style: Style
    let avatarUrl: URL?
    let name: String
    let portal: String
    let isActiveUser: Bool
    let showProfileCallback: () -> Void
    let selectCallback: () -> Void
    let deleteCallback: () -> Void

    init(style: Style = .init(),
         avatarUrl: URL?,
         name: String,
         portal: String,
         isActiveUser: Bool,
         showProfileCallback: @escaping () -> Void,
         selectCallback: @escaping () -> Void,
         deleteCallback: @escaping () -> Void)
    {
        self.style = style
        self.avatarUrl = avatarUrl
        self.name = name
        self.portal = portal
        self.isActiveUser = isActiveUser
        self.showProfileCallback = showProfileCallback
        self.selectCallback = selectCallback
        self.deleteCallback = deleteCallback
    }
}

struct AddAccountCellModel {
    struct Style {
        let textColor: UIColor
    }

    let image: String
    let text: String
    let style: Style

    init(image: String,
         text: String,
         style: Style = .init(textColor: UIColor(asset: Asset.Colors.brend) ?? UIColor.systemBlue))
    {
        self.image = image
        self.text = text
        self.style = style
    }
}
