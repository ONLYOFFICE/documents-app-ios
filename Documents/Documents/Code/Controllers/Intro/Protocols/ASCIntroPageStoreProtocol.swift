//
//  ASCIntroPageStoreProtocol.swift
//  Documents
//
//  Created by Alexander Yuzhin on 23.10.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol ASCIntroPageStoreProtocol {
    func fetch() -> [ASCIntroPage]
}
