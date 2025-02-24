//
//  ASCSharingRightHolderViewModelProtocol.swift
//  Documents
//
//  Created by Pavel Chernyshev on 01.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol ASCSharingRightHolderViewModelProtocol: ASCNamedProtocol {
    var avatarUrl: String? { get }
    var name: String { get set }
    var department: String? { get }
    var isOwner: Bool { get }
    var rightHolderType: ASCSharingRightHolderType? { get }
    var access: ASCSharingRightHolderViewModelAccess? { get }
}

enum ASCSharingRightHolderType: String {
    case user
    case group
    case guest
    case link
    case email
}

struct ASCSharingRightHolderViewModelAccess {
    var entityAccess: ASCShareAccess
    var accessEditable: Bool
}
