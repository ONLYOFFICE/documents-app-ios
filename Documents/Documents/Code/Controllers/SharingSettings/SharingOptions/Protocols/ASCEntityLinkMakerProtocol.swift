//
//  EntityLinkMakerProtocol.swift
//  Documents
//
//  Created by Pavel Chernyshev on 06.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol ASCEntityLinkMakerProtocol {
    func make(entity: ASCEntity) -> String?
}
