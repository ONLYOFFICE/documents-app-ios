//
//  ASCSwitchRowViewModel.swift
//  Documents
//
//  Created by Павел Чернышев on 11.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

struct ASCSwitchRowViewModel {
    var title: String
    var isActive: Bool
    var toggleHandler: (Bool) -> Void
}
