//
//  ASCSharingOptionsRightHolderViewModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 10.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

struct ASCSharingRightHolderViewModel: ASCNamedProtocol, ASCSharingRightHolderViewModelProtocol, Identifiable {
    var id: String
    var avatarUrl: String?
    var name: String
    var department: String?
    var isOwner: Bool = false
    var isImportant: Bool = false
    var rightHolderType: ASCSharingRightHolderType?
    var access: ASCSharingRightHolderViewModelAccess?
}
