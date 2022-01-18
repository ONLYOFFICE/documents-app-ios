//
//  ASCSharingSettingsAccessNotesProviderProtocol.swift
//  Documents
//
//  Created by Павел Чернышев on 04.08.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

typealias ShareAccessNote = String
protocol ASCSharingSettingsAccessNotesProviderProtocol {
    func get(for access: ASCShareAccess) -> ShareAccessNote?
}
