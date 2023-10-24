//
//  ASCShareSettingsAPIWorkerFactory.swift
//  Documents
//
//  Created by Pavel Chernyshev on 24.11.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCShareSettingsAPIWorkerFactory {
    func get(by portalType: ASCPortalType, entity: ASCEntity? = nil) -> ASCShareSettingsAPIWorkerProtocol {
        switch portalType {
        case .personal:
            return ASCPersonalShareSettingsAPIWorker()
        case .docSpace:
            return ASCShareSettingsRoomsAPIWorker(baseWorker: ASCShareSettingsAPIWorker())
        case .unknown:
            return ASCShareSettingsAPIWorker()
        }
    }
}
