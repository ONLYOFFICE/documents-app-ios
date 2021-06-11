//
//  ASCSharingOptionsRightHolderViewModel.swift
//  Documents
//
//  Created by Павел Чернышев on 10.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

struct ASCSharingOptionsRightHolderViewModel {
    
    enum RightHolder: String {
        case manager
        case designer
        case group
    }
    
    var avatar: UIImage
    var name: String
    var isOwner: Bool
    var rightHolder: RightHolder
    var documetAccess: ASCShareAccess
    var accessEditable: Bool
}
