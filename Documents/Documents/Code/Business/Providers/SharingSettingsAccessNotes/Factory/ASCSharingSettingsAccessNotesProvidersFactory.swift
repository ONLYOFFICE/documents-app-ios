//
//  ASCSharingSettingsAccessNotesProvidersFactory.swift
//  Documents
//
//  Created by Павел Чернышев on 04.08.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCSharingSettingsAccessNotesProvidersFactory {
    
    func get(accessType: AccessType) -> ASCSharingSettingsAccessNotesProviderProtocol {
        switch accessType {
        case .externalLink:
            return ASCSharingSettingsAccessForExternalLinkNotesProvider()
        case .userOrGroup:
            return ASCSharingSettingsAccessForUserOrGroupNotesProvider()
        }
    }
    
    enum AccessType {
        case externalLink
        case userOrGroup
    }
}
