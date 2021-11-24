//
//  ASCShareSettingsAPIWorkerFactory.swift
//  Documents
//
//  Created by Павел Чернышев on 24.11.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCShareSettingsAPIWorkerFactory {
    func get(by portalHost: String?) -> ASCShareSettingsAPIWorkerProtocol {
        let defaultAPIWorker = ASCShareSettingsAPIWorker()
        guard let portalHost = portalHost else {
            return defaultAPIWorker
        }
        
        if portalHost == "personal.teamlab.info" {
            return ASCPersonalShareSettingsAPIWorker()
        }
        
        return defaultAPIWorker
    }
}
