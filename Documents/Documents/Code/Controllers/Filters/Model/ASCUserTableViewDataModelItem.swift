//
//  ASCUserTableViewDataModelItem.swift
//  Documents
//
//  Created by Lolita Chernysheva on 15.04.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation

struct ASCUserTableViewDataModelItem {
    var id: String?
    var avatarImageUrl: String?
    var userName: String?
    var userPosition: String?
    var isSelected: Bool
    var isOwner: Bool = false
}
