//
//  AccountCellModel.swift
//  Documents-opensource
//
//  Created by Лолита Чернышева on 03.04.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import UIKit

struct AccountCellModel {
    struct Style {
        let nameFont: UIFont
        let emailFont: UIFont

        init(nameFont: UIFont = UIFont.systemFont(ofSize: 15),
             emailFont: UIFont = UIFont.systemFont(ofSize: 13))
        {
            self.nameFont = nameFont
            self.emailFont = emailFont
        }
    }

    let style: Style
    let avatarUrlString: String?
    let name: String
    let email: String
    let isActiveUser: Bool

    init(style: Style = .init(), avatarUrlString: String, name: String, email: String, isActiveUser: Bool) {
        self.style = style
        self.avatarUrlString = avatarUrlString
        self.name = name
        self.email = email
        self.isActiveUser = isActiveUser
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
