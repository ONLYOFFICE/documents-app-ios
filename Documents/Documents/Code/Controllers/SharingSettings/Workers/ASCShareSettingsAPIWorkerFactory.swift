//
//  ASCShareSettingsAPIWorkerFactory.swift
//  Documents
//
//  Created by Павел Чернышев on 24.11.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCShareSettingsAPIWorkerFactory {
    func get(by portalType: ASCPortalType) -> ASCShareSettingsAPIWorkerProtocol {
        switch portalType {
        case .personal:
            return ASCPersonalShareSettingsAPIWorker()
        case .unknown:
            return ASCShareSettingsAPIWorker()
        }
    }
}
