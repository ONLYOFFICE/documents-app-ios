//
//  UISplitViewController+Extensions.swift
//  Documents
//
//  Created by Alexander Yuzhin on 26/06/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import UIKit

extension UISplitViewController {
    func hideMasterController() {
        let originPreferredDisplayMode = preferredDisplayMode
        preferredDisplayMode = .primaryHidden
        preferredDisplayMode = originPreferredDisplayMode
    }
}
