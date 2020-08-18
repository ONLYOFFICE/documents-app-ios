//
//  ASCShareInfo.swift
//  Documents
//
//  Created by Alexander Yuzhin on 6/8/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import Foundation

struct  ASCShareInfo {
    var access: ASCShareAccess = .none
    var user: ASCUser? = nil
    var group: ASCGroup? = nil
    var locked: Bool = false
    var owner: Bool = false
    var shareLink: String? = nil
}
