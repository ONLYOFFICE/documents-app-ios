//
//  ASCSharingOptionsRightHolderViewModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 10.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

struct ASCSharingRightHolderViewModel: ASCNamedProtocol {
    
    enum RightHolderType: String {
        case user
        case group
    }
    
    struct Access {
        var documetAccess: ASCShareAccess
        var accessEditable: Bool
    }
    
    var avatarUrl: String?
    var name: String
    var department: String?
    var isOwner: Bool = false
    var rightHolderType: RightHolderType?
    var access: Access?
}
