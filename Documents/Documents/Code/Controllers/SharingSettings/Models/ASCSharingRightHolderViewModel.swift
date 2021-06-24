//
//  ASCSharingOptionsRightHolderViewModel.swift
//  Documents
//
//  Created by Павел Чернышев on 10.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

struct ASCSharingRightHolderViewModel: ASCNamedProtocol {
    
    enum RightHolderType: String {
        case manager
        case designer
        case group
        
        // MARK: - todo add lang description
    }
    
    struct Access {
        var documetAccess: ASCShareAccess
        var accessEditable: Bool
    }
    
    var avatar: UIImage
    var name: String
    var isOwner: Bool = false
    var rightHolderType: RightHolderType?
    var access: Access?
}
