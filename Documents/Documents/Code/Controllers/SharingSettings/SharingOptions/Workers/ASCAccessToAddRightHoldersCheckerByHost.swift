//
//  ASCAccessToAddRightHoldersCheckerByHost.swift
//  Documents
//
//  Created by Павел Чернышев on 24.11.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCAccessToAddRightHoldersCheckerByHost: ASCAccessToAddRightHoldersCheckerProtocol {
    let host: String?
    
    init(host: String?) {
        self.host = host
    }
    
    func checkAccessToAddRightHolders() -> Bool {
        guard let host = host else {
            return false
        }
        
        return host != "personal.teamlab.info"
    }
}
