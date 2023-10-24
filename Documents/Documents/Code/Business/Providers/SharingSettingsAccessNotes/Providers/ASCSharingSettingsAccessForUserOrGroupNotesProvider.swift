//
//  ASCSharingSettingsAccessForUserOrGroupNotesProvider.swift
//  Documents
//
//  Created by Pavel Chernyshev on 04.08.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCSharingSettingsAccessForUserOrGroupNotesProvider: ASCSharingSettingsAccessNotesProviderProtocol {
    func get(for access: ASCShareAccess) -> ShareAccessNote? {
        switch access {
        case .full:
            return NSLocalizedString("A user or group will be able to view and edit the document as well as to share this document.", comment: "")
        case .read:
            return NSLocalizedString("A user or group will be able only to view the document.", comment: "")
        case .deny:
            return NSLocalizedString("This option is used to block access previously granted to a user or group.", comment: "")
        case .review:
            return NSLocalizedString("A user or group will be able to view and change the document without actually editing it, but all the changes made by a reviewer will be recorded and shown to the file owner (or a person who has full access to the file) so that he/she will be able to accept or reject them.", comment: "")
        case .comment:
            return NSLocalizedString("A user or group will be able only to view the document and add comments, as well as manage them.", comment: "")
        case .fillForms:
            return NSLocalizedString("A user or group will be able only to view the document and fill in the forms inserted into the document.", comment: "")
        default:
            return nil
        }
    }
}
