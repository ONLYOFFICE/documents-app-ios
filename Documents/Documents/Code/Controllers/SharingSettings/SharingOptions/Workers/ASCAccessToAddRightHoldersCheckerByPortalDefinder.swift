//
//  ASCAccessToAddRightHoldersCheckerByPortalDefinder.swift
//  Documents
//
//  Created by Павел Чернышев on 25.11.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCAccessToAddRightHoldersCheckerByPortalDefinder: ASCAccessToAddRightHoldersCheckerProtocol {
    let portalType: ASCPortalType

    init(portalType: ASCPortalType) {
        self.portalType = portalType
    }

    func checkAccessToAddRightHolders() -> Bool {
        switch portalType {
        case .personal: return false
        case .docSpace, .unknown: return true
        }
    }
}
