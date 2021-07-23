//
//  ASCSharingSettingsAccessViewModel.swift
//  Documents
//
//  Created by Павел Чернышев on 15.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

struct ASCSharingSettingsAccessViewModel {
    var title: String?
    var currentlyAccess: ASCShareAccess? = .read
    var accessProvider: ASCSharingSettingsAccessProvider?
    var largeTitleDisplayMode:  UINavigationItem.LargeTitleDisplayMode = .automatic
    var headerText: String = NSLocalizedString("Access settings", comment: "")
    var footerText: String = NSLocalizedString("Unauthorized users will not be able to view the document.", comment: "")
    
    var selectAccessDelegate: ((ASCShareAccess) -> Void)?
}
